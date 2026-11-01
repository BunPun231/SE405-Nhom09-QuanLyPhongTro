import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/meter_reading_service.dart';
import '../../../core/services/motel_service.dart';
import '../../../core/services/service_service.dart';
import '../tenant/meter/meter_history_view.dart';
import '../tenant/meter/meter_submit_screen.dart';
import '../tenant/meter/meter_widgets.dart';
import 'meter/meter_review_card.dart';

const _meteredTypes = ['METERED', 'TIERED', 'PER_QUANTITY', 'PER_INDEX'];

/// Quản lý: đối soát & duyệt chỉ số điện/nước (UC70), tự chốt số có OCR (UC71),
/// xem lịch sử theo phòng (UC72).
class ManagerUtilityReadingScreen extends StatefulWidget {
  const ManagerUtilityReadingScreen({super.key});

  @override
  State<ManagerUtilityReadingScreen> createState() => _ManagerUtilityReadingScreenState();
}

class _StatusFilter {
  final String key;
  final String label;
  const _StatusFilter(this.key, this.label);
}

const _filters = [
  _StatusFilter(MeterStatus.pending, 'Chờ duyệt'),
  _StatusFilter('MISSING', 'Chưa ghi'),
  _StatusFilter(MeterStatus.rejected, 'Từ chối'),
  _StatusFilter(MeterStatus.approved, 'Đã duyệt'),
  _StatusFilter('ALL', 'Tất cả'),
];

class _ManagerUtilityReadingScreenState extends State<ManagerUtilityReadingScreen> {
  List<MotelResult> _motels = [];
  int? _motelId;
  List<RoomResult> _rooms = [];
  List<ServiceResult> _services = [];
  List<MeterReading> _readings = [];

  bool _loading = true;
  String? _error;
  late String _monthKey;
  String _filter = MeterStatus.pending;
  final Set<int> _busyIds = {};
  bool _bulkBusy = false;

  @override
  void initState() {
    super.initState();
    _monthKey = MeterRules.monthKeyOf(DateTime.now());
    _loadMotels();
  }

  Future<void> _loadMotels() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await MotelService.list(size: 50);
      if (!mounted) return;
      setState(() {
        _motels = res.content;
        _motelId = res.content.isNotEmpty ? res.content.first.id : null;
      });
      if (_motelId == null) {
        setState(() => _loading = false);
        return;
      }
      await _fetch();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = meterErrorText(e);
        });
      }
    }
  }

  Future<void> _fetch() async {
    final motelId = _motelId;
    if (motelId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rooms = await RoomService.list(motelId, size: 300);
      final services = await ServiceService.list(motelId);
      final readings = await MeterReadingApi.list(size: 2000);
      if (!mounted || motelId != _motelId) return;
      final roomIds = rooms.content.map((r) => r.id).toSet();
      setState(() {
        _rooms = rooms.content..sort((a, b) => a.roomNumber.compareTo(b.roomNumber));
        _services = services.where((s) => _meteredTypes.contains(s.chargeType)).toList();
        _readings = readings.where((r) => roomIds.contains(r.roomId)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = meterErrorText(e);
      });
    }
  }

  Future<void> _refreshReadings() async {
    try {
      final readings = await MeterReadingApi.list(size: 2000);
      final roomIds = _rooms.map((r) => r.id).toSet();
      if (mounted) setState(() => _readings = readings.where((r) => roomIds.contains(r.roomId)).toList());
    } catch (e) {
      _snack('Không tải lại được: ${meterErrorText(e)}', error: true);
    }
  }

  // ── Dữ liệu kỳ đang xem ───────────────────────────────────────────────────

  List<MeterReviewEntry> get _entries {
    final result = <MeterReviewEntry>[];
    for (final room in _rooms) {
      final hasReading = _readings.any((r) => r.roomId == room.id && r.monthKey == _monthKey);
      // Phòng trống/ngừng kinh doanh không cần chốt số, trừ khi đã có bản ghi.
      if (!hasReading && ['EMPTY', 'AVAILABLE', 'OUT_OF_BUSINESS'].contains(room.status)) continue;
      for (final svc in _services) {
        final candidates = _readings
            .where((r) => r.roomId == room.id && r.serviceId == svc.id && r.monthKey == _monthKey)
            .toList()
          ..sort((a, b) {
            if (a.isApproved != b.isApproved) return a.isApproved ? -1 : 1;
            return (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0));
          });
        final past = _readings
            .where((r) => r.roomId == room.id && r.serviceId == svc.id && r.isApproved && r.monthKey.compareTo(_monthKey) < 0)
            .toList()
          ..sort((a, b) => b.monthKey.compareTo(a.monthKey));
        result.add(MeterReviewEntry(
          roomId: room.id,
          roomLabel: room.roomNumber,
          serviceId: svc.id,
          serviceName: svc.name,
          unit: svc.unit,
          reading: candidates.isEmpty ? null : candidates.first,
          knownOldReading: past.isEmpty ? null : past.first.newReading,
          average: MeterRules.averageConsumption(
            _readings,
            roomId: room.id,
            serviceId: svc.id,
            beforeMonthKey: _monthKey,
          ),
        ));
      }
    }
    return result;
  }

  // ── Hành động ─────────────────────────────────────────────────────────────

  Future<void> _approve(MeterReviewEntry e) async {
    final r = e.reading!;
    if (e.isHighConsumption) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Tiêu thụ bất thường'),
          content: Text(
            'Phòng ${e.roomLabel} dùng ${MeterRules.formatReading(r.consumption)} '
            '(trung bình ${MeterRules.formatReading(e.average?.roundToDouble())}). '
            'Bạn đã đối chiếu ảnh đồng hồ và vẫn muốn duyệt?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Xem lại')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: MeterTone.confirm),
              child: const Text('Vẫn duyệt'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _busyIds.add(r.id));
    try {
      await MeterReadingApi.approve(r.id);
      _snack('Đã duyệt ${e.serviceName} phòng ${e.roomLabel}.');
      await _refreshReadings();
    } catch (err) {
      _snack('Không duyệt được: ${meterErrorText(err)}', error: true);
    } finally {
      if (mounted) setState(() => _busyIds.remove(r.id));
    }
  }

  Future<void> _reject(MeterReviewEntry e) async {
    final reason = await askMeterRejectReason(context, e);
    if (reason == null || reason.trim().isEmpty) return;
    final r = e.reading!;
    setState(() => _busyIds.add(r.id));
    try {
      await MeterReadingApi.reject(r.id, reason.trim());
      _snack('Đã từ chối. Khách thuê sẽ thấy lý do để gửi lại.');
      await _refreshReadings();
    } catch (err) {
      _snack('Không từ chối được: ${meterErrorText(err)}', error: true);
    } finally {
      if (mounted) setState(() => _busyIds.remove(r.id));
    }
  }

  Future<void> _record(MeterReviewEntry e) async {
    final saved = await Navigator.push<MeterReading>(
      context,
      MaterialPageRoute(
        builder: (_) => MeterSubmitScreen(
          roomId: e.roomId,
          roomLabel: e.roomLabel,
          serviceId: e.serviceId,
          serviceName: e.serviceName,
          unit: e.unit,
          monthKey: _monthKey,
          knownOldReading: e.knownOldReading,
          existing: e.reading,
          isManager: true,
        ),
      ),
    );
    if (saved == null || !mounted) return;
    _snack('Đã chốt ${e.serviceName} phòng ${e.roomLabel}: ${MeterStatus.label(saved.status)}.');
    await _refreshReadings();
  }

  /// Duyệt hàng loạt các bản chờ duyệt, bỏ qua bản có cảnh báo tiêu thụ cao (BR70.7).
  Future<void> _bulkApprove(List<MeterReviewEntry> eligible, int flagged) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Duyệt ${eligible.length} chỉ số?'),
        content: Text(
          'Các chỉ số chờ duyệt của ${MeterRules.monthLabel(_monthKey).toLowerCase()} sẽ được chốt để tính hóa đơn.'
          '${flagged > 0 ? '\n\n$flagged mục có tiêu thụ bất thường không được duyệt nhanh, hãy kiểm tra từng mục.' : ''}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: MeterTone.confirm),
            child: const Text('Duyệt'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _bulkBusy = true);
    try {
      await MeterReadingApi.bulkApprove(eligible.map((e) => e.reading!.id).toList());
      _snack('Đã duyệt ${eligible.length} chỉ số.');
      await _refreshReadings();
    } catch (err) {
      _snack('Duyệt hàng loạt thất bại: ${meterErrorText(err)}', error: true);
      await _refreshReadings();
    } finally {
      if (mounted) setState(() => _bulkBusy = false);
    }
  }

  Future<void> _pickMonth() async {
    final key = await pickMeterMonth(context, _monthKey);
    if (key != null && key != _monthKey) setState(() => _monthKey = key);
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? MeterTone.dangerText : MeterTone.successText,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Column(
          children: [
            Material(
              color: Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      children: [
                        Expanded(child: _buildMotelPicker()),
                        const SizedBox(width: 10),
                        MeterMonthButton(monthKey: _monthKey, onPressed: _pickMonth),
                      ],
                    ),
                  ),
                  const TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondaryLight,
                    indicatorColor: AppColors.primary,
                    labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    tabs: [Tab(text: 'Duyệt chỉ số'), Tab(text: 'Lịch sử')],
                  ),
                  const Divider(height: 1, color: AppColors.borderLight),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : _error != null
                      ? MeterEmptyState(
                          icon: Icons.error_outline_rounded,
                          title: 'Không tải được dữ liệu',
                          message: _error,
                          actionLabel: 'Thử lại',
                          onAction: _motels.isEmpty ? _loadMotels : _fetch,
                        )
                      : _motelId == null
                          ? const MeterEmptyState(
                              icon: Icons.apartment_rounded,
                              title: 'Chưa có khu trọ',
                              message: 'Tạo khu trọ và phòng trước khi chốt chỉ số.',
                            )
                          : TabBarView(
                              children: [
                                _buildReviewTab(),
                                MeterHistoryView(
                                  key: ValueKey('history-$_motelId'),
                                  rooms: _rooms
                                      .map((r) => MeterRoomOption(id: r.id, label: r.roomNumber))
                                      .toList(),
                                ),
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotelPicker() {
    if (_motels.isEmpty) {
      return const Text('Chỉ số điện nước',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight));
    }
    return DropdownButtonFormField<int>(
      initialValue: _motelId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Khu trọ',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      items: _motels
          .map((m) => DropdownMenuItem(value: m.id, child: Text(m.name, overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: (v) {
        if (v == null || v == _motelId) return;
        setState(() => _motelId = v);
        _fetch();
      },
    );
  }

  Widget _buildReviewTab() {
    final entries = _entries;
    final counts = <String, int>{};
    for (final e in entries) {
      counts[e.statusKey] = (counts[e.statusKey] ?? 0) + 1;
    }
    final visible = _filter == 'ALL' ? entries : entries.where((e) => e.statusKey == _filter).toList();
    final pending = entries.where((e) => e.statusKey == MeterStatus.pending).toList();
    final eligible = pending.where((e) => !e.isHighConsumption).toList();
    final flagged = pending.length - eligible.length;

    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((f) {
                final n = f.key == 'ALL' ? entries.length : (counts[f.key] ?? 0);
                final selected = _filter == f.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${f.label} ($n)'),
                    selected: selected,
                    showCheckmark: true,
                    checkmarkColor: Colors.white,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: selected ? AppColors.primary : AppColors.borderLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textSecondaryLight,
                    ),
                    onSelected: (_) => setState(() => _filter = f.key),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          if (pending.isNotEmpty && (_filter == MeterStatus.pending || _filter == 'ALL')) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: eligible.isEmpty || _bulkBusy ? null : () => _bulkApprove(eligible, flagged),
                icon: _bulkBusy
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.done_all_rounded, size: 18),
                label: Text('Duyệt nhanh ${eligible.length} chỉ số'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: MeterTone.confirm,
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            if (flagged > 0) ...[
              const SizedBox(height: 8),
              MeterNotice.warning('$flagged mục tiêu thụ bất thường phải duyệt từng mục.'),
            ],
            const SizedBox(height: 12),
          ],
          if (_services.isEmpty)
            const MeterEmptyState(
              icon: Icons.speed_rounded,
              title: 'Khu trọ chưa có dịch vụ tính theo chỉ số',
              message: 'Thêm dịch vụ điện/nước theo đồng hồ trong mục Dịch vụ.',
            )
          else if (visible.isEmpty)
            MeterEmptyState(
              icon: Icons.inbox_outlined,
              title: _filter == MeterStatus.pending ? 'Không có chỉ số chờ duyệt' : 'Không có mục nào',
              message: MeterRules.monthLabel(_monthKey),
            )
          else
            ...visible.map((e) => MeterReviewCard(
                  key: ValueKey('${e.roomId}-${e.serviceId}'),
                  entry: e,
                  busy: _bulkBusy || (e.reading != null && _busyIds.contains(e.reading!.id)),
                  onApprove: () => _approve(e),
                  onReject: () => _reject(e),
                  onRecord: () => _record(e),
                )),
        ],
      ),
    );
  }
}
