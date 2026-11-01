import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/contract_service.dart';
import '../../../core/services/meter_reading_service.dart';
import '../../../core/services/motel_service.dart';
import '../../../core/services/service_service.dart';
import 'meter/meter_history_view.dart';
import 'meter/meter_submit_screen.dart';
import 'meter/meter_widgets.dart';

const _meteredTypes = ['METERED', 'TIERED', 'PER_QUANTITY', 'PER_INDEX'];

/// Khách thuê: khai báo chỉ số điện/nước hằng tháng (UC70, UC71) và xem lịch sử (UC72).
class TenantUtilityReadingScreen extends StatefulWidget {
  const TenantUtilityReadingScreen({super.key});

  @override
  State<TenantUtilityReadingScreen> createState() => _TenantUtilityReadingScreenState();
}

class _TenantUtilityReadingScreenState extends State<TenantUtilityReadingScreen> {
  int? _roomId;
  String _roomLabel = '';
  String? _contractCode;
  List<ServiceResult> _services = [];
  List<MeterReading> _readings = [];
  bool _loading = true;
  String? _error;
  late String _monthKey;

  @override
  void initState() {
    super.initState();
    _monthKey = MeterRules.monthKeyOf(DateTime.now());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final contracts = await ContractService.listMine();
      if (contracts.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Bạn chưa có hợp đồng thuê phòng nào đang hoạt động.';
        });
        return;
      }
      final contract = contracts.first;
      final detail = await ContractService.getDetail(contract.id);
      final motelId = detail.motelId;
      if (motelId == null) {
        setState(() {
          _loading = false;
          _error = 'Không tìm thấy thông tin khu trọ của phòng thuê.';
        });
        return;
      }
      var label = '${contract.roomId}';
      try {
        label = (await RoomService.get(motelId, contract.roomId)).roomNumber;
      } catch (_) {}
      final services = await ServiceService.listByRoom(motelId, contract.roomId);
      final readings = await MeterReadingApi.list(roomId: contract.roomId);
      if (!mounted) return;
      setState(() {
        _roomId = contract.roomId;
        _roomLabel = label.isEmpty ? '${contract.roomId}' : label;
        _contractCode = contract.contractCode;
        _services = services.where((s) => _meteredTypes.contains(s.chargeType)).toList();
        _readings = readings;
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

  Future<void> _reloadReadings() async {
    if (_roomId == null) return;
    try {
      final readings = await MeterReadingApi.list(roomId: _roomId);
      if (mounted) setState(() => _readings = readings);
    } catch (_) {}
  }

  MeterReading? _currentFor(int serviceId) {
    final list = _readings.where((r) => r.serviceId == serviceId && r.monthKey == _monthKey).toList()
      ..sort((a, b) {
        // Ưu tiên bản đã duyệt, sau đó bản mới nhất.
        if (a.isApproved != b.isApproved) return a.isApproved ? -1 : 1;
        return (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0));
      });
    return list.isEmpty ? null : list.first;
  }

  double? _oldFor(int serviceId) {
    final past = _readings
        .where((r) => r.serviceId == serviceId && r.isApproved && r.monthKey.compareTo(_monthKey) < 0)
        .toList()
      ..sort((a, b) => b.monthKey.compareTo(a.monthKey));
    return past.isEmpty ? null : past.first.newReading;
  }

  Future<void> _pickMonth() async {
    final key = await pickMeterMonth(context, _monthKey);
    if (key != null && key != _monthKey) setState(() => _monthKey = key);
  }

  Future<void> _openSubmit(ServiceResult svc, MeterReading? current) async {
    final saved = await Navigator.push<MeterReading>(
      context,
      MaterialPageRoute(
        builder: (_) => MeterSubmitScreen(
          roomId: _roomId!,
          roomLabel: _roomLabel,
          serviceId: svc.id,
          serviceName: svc.name,
          unit: svc.unit,
          monthKey: _monthKey,
          knownOldReading: _oldFor(svc.id),
          existing: current,
        ),
      ),
    );
    if (saved == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã gửi chỉ số ${svc.name}. Trạng thái: ${MeterStatus.label(saved.status)}.'),
        backgroundColor: MeterTone.successText,
      ),
    );
    _reloadReadings();
  }

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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _roomId == null ? 'Chỉ số điện nước' : 'Phòng $_roomLabel',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
                              ),
                              if (_contractCode != null)
                                Text('Hợp đồng $_contractCode',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                            ],
                          ),
                        ),
                        MeterMonthButton(monthKey: _monthKey, onPressed: _pickMonth),
                      ],
                    ),
                  ),
                  const TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondaryLight,
                    indicatorColor: AppColors.primary,
                    labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    tabs: [Tab(text: 'Khai báo tháng'), Tab(text: 'Lịch sử')],
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
                          onAction: _load,
                        )
                      : TabBarView(
                          children: [
                            _buildDeclareTab(),
                            MeterHistoryView(
                              rooms: [MeterRoomOption(id: _roomId!, label: _roomLabel)],
                              initialRoomId: _roomId,
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeclareTab() {
    if (_services.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 80),
            MeterEmptyState(
              icon: Icons.speed_rounded,
              title: 'Chưa có dịch vụ tính theo chỉ số',
              message: 'Phòng chưa được gán dịch vụ điện hoặc nước theo đồng hồ.',
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _reloadReadings,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          MeterNotice.info('Chụp ảnh mặt đồng hồ, hệ thống sẽ đọc số giúp bạn. Bạn luôn kiểm tra và sửa được trước khi gửi.'),
          const SizedBox(height: 12),
          ..._services.map((s) => _buildServiceCard(s, _currentFor(s.id))),
        ],
      ),
    );
  }

  Widget _buildServiceCard(ServiceResult svc, MeterReading? current) {
    final old = current?.oldReading ?? _oldFor(svc.id);
    final isCurrentMonth = _monthKey == MeterRules.monthKeyOf(DateTime.now());
    final canSubmit = current == null || !current.isApproved;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MeterTone.mist),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MeterServiceIcon(svc.name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(svc.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MeterTone.heading)),
                    Text(MeterRules.monthLabel(_monthKey),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                  ],
                ),
              ),
              MeterStatusBadge(current?.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: MeterNumbersRow(
                  oldReading: old,
                  newReading: current?.newReading,
                  consumption: current?.consumption,
                  unit: svc.unit,
                ),
              ),
              if (current?.imageUrl != null) ...[
                const SizedBox(width: 10),
                MeterImageThumb(url: current!.imageUrl, size: 64),
              ],
            ],
          ),
          if (current != null && current.isRejected) ...[
            const SizedBox(height: 12),
            MeterNotice.danger(
              'Bị từ chối${current.rejectReason != null ? ': ${current.rejectReason}' : ''}. Vui lòng gửi lại.',
            ),
          ],
          if (current != null && current.isPending) ...[
            const SizedBox(height: 12),
            MeterNotice.warning('Đang chờ Quản lý đối chiếu ảnh và duyệt.'),
          ],
          if (current != null && current.isApproved) ...[
            const SizedBox(height: 12),
            MeterNotice.success('Đã duyệt. Chỉ số này được dùng để tính hóa đơn.'),
          ],
          if (canSubmit) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: current == null || current.isRejected
                  ? FilledButton.icon(
                      onPressed: () => _openSubmit(svc, current),
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: Text(current == null ? 'Khai báo chỉ số' : 'Gửi lại chỉ số'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        backgroundColor: AppColors.primary,
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: () => _openSubmit(svc, current),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Sửa và gửi lại'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        foregroundColor: AppColors.textPrimaryLight,
                        side: const BorderSide(color: AppColors.borderLight),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
            ),
            if (!isCurrentMonth && current == null)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Bạn đang khai báo cho một kỳ đã qua.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
              ),
          ],
        ],
      ),
    );
  }
}
