import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/invoice_service.dart';
import '../../../core/services/motel_service.dart';
import '../../../core/services/service_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models for the room×service matrix
// ─────────────────────────────────────────────────────────────────────────────
class _RoomRow {
  final int roomId;
  final String roomNumber;
  final List<_RoomServiceCell> services;
  _RoomRow({required this.roomId, required this.roomNumber, required this.services});
}

class _RoomServiceCell {
  final int serviceId;
  final String serviceName;
  final double oldReading;
  final MeterReadingResult? currentReading;
  _RoomServiceCell({required this.serviceId, required this.serviceName, required this.oldReading, this.currentReading});
}

class _PendingItem {
  final int roomId;
  final String roomNumber;
  final int serviceId;
  final String serviceName;
  final double oldReading;
  final MeterReadingResult reading;
  _PendingItem({required this.roomId, required this.roomNumber, required this.serviceId, required this.serviceName, required this.oldReading, required this.reading});
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────────────────
class ManagerUtilityReadingScreen extends StatefulWidget {
  const ManagerUtilityReadingScreen({Key? key}) : super(key: key);

  @override
  State<ManagerUtilityReadingScreen> createState() => _ManagerUtilityReadingScreenState();
}

class _ManagerUtilityReadingScreenState extends State<ManagerUtilityReadingScreen> {
  List<MotelResult> _motels = [];
  int? _selectedMotelId;

  List<RoomResult> _rooms = [];
  List<ServiceResult> _services = [];
  List<MeterReadingResult> _readings = [];

  bool _isLoading = false;
  String? _error;
  late String _billingMonth;
  bool _bulkLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _billingMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _loadMotels();
  }

  Future<void> _loadMotels() async {
    try {
      final res = await MotelService.list(size: 50);
      if (mounted) {
        setState(() {
          _motels = res.content;
          if (res.content.isNotEmpty) _selectedMotelId = res.content.first.id;
        });
        if (_selectedMotelId != null) _fetchData();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _fetchData() async {
    if (_selectedMotelId == null) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final roomsRes = await RoomService.list(_selectedMotelId!, size: 200);
      final servicesRes = await ServiceService.list(_selectedMotelId!);
      final readingsRes = await MeterReadingService.list(size: 500);
      if (mounted) {
        setState(() {
          _rooms = roomsRes.content;
          _services = servicesRes.where((s) => ['METERED', 'TIERED', 'PER_QUANTITY', 'PER_INDEX'].contains(s.chargeType)).toList();
          _readings = readingsRes.content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  List<_RoomRow> get _tableData {
    final targetMonth = '$_billingMonth-01';
    final List<_RoomRow> result = [];
    for (final room in _rooms) {
      if (['EMPTY', 'AVAILABLE', 'OUT_OF_BUSINESS'].contains(room.status)) continue;
      final cells = <_RoomServiceCell>[];
      for (final svc in _services) {
        MeterReadingResult? currentReading;
        for (final r in _readings) {
          if (r.roomId == room.id && r.serviceId == svc.id && r.billingMonth == targetMonth) {
            currentReading = r;
            break;
          }
        }
        final pastApproved = _readings
            .where((r) => r.roomId == room.id && r.serviceId == svc.id && r.status == 'APPROVED' && r.billingMonth.compareTo(targetMonth) < 0)
            .toList()
          ..sort((a, b) => b.billingMonth.compareTo(a.billingMonth));
        final oldReading = pastApproved.isNotEmpty ? (pastApproved.first.newReading ?? 0) : 0.0;
        cells.add(_RoomServiceCell(serviceId: svc.id, serviceName: svc.name, oldReading: oldReading, currentReading: currentReading));
      }
      result.add(_RoomRow(roomId: room.id, roomNumber: room.roomNumber, services: cells));
    }
    return result;
  }

  List<_PendingItem> get _pendingItems {
    final result = <_PendingItem>[];
    for (final row in _tableData) {
      for (final cell in row.services) {
        if (cell.currentReading != null && (cell.currentReading!.status == 'PENDING' || cell.currentReading!.status == 'SUBMITTED')) {
          result.add(_PendingItem(roomId: row.roomId, roomNumber: row.roomNumber, serviceId: cell.serviceId, serviceName: cell.serviceName, oldReading: cell.oldReading, reading: cell.currentReading!));
        }
      }
    }
    return result;
  }

  int get _pendingCount {
    int c = 0;
    for (final row in _tableData) {
      for (final cell in row.services) {
        if (cell.currentReading == null || cell.currentReading!.status == 'PENDING' || cell.currentReading!.status == 'SUBMITTED') c++;
      }
    }
    return c;
  }

  Future<void> _approve(int id) async {
    try { await MeterReadingService.approve(id); _fetchData(); _showSnack('Đã phê duyệt!', success: true); } catch (e) { _showSnack('Lỗi: $e'); }
  }

  Future<void> _reject(int id) async {
    final reason = await _askReason();
    if (reason == null) return;
    try { await MeterReadingService.reject(id, reason: reason); _fetchData(); _showSnack('Đã từ chối.'); } catch (e) { _showSnack('Lỗi: $e'); }
  }

  Future<void> _bulkApprove() async {
    final pending = _pendingItems;
    if (pending.isEmpty) return;
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Duyệt tất cả', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text('Duyệt ${pending.length} chỉ số đang chờ?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Xác nhận')),
      ],
    ));
    if (confirm != true) return;
    setState(() => _bulkLoading = true);
    try {
      await MeterReadingService.bulkApprove(pending.map((p) => p.reading.id).toList());
      _fetchData(); _showSnack('Đã duyệt tất cả ${pending.length} chỉ số!', success: true);
    } catch (e) { _showSnack('Lỗi: $e'); }
    finally { if (mounted) setState(() => _bulkLoading = false); }
  }

  Future<String?> _askReason() => showDialog<String>(context: context, builder: (ctx) {
    final ctrl = TextEditingController();
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Lý do từ chối', style: TextStyle(fontWeight: FontWeight.bold)),
      content: TextField(controller: ctrl, autofocus: true, decoration: InputDecoration(hintText: 'Nhập lý do...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim().isEmpty ? 'Chỉ số không hợp lệ' : ctrl.text.trim()), style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Từ chối')),
      ],
    );
  });

  void _showSnack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: success ? AppColors.success : null, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  void _showImageLightbox(String url) {
    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Minh chứng chỉ số', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(url, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 80))),
        const SizedBox(height: 12),
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
      ])),
    ));
  }

  void _showSubmitReadingSheet(int roomId, String roomNumber) {
    final rowData = _tableData.firstWhere((r) => r.roomId == roomId);
    final ctrls = <int, TextEditingController>{};
    for (final cell in rowData.services) {
      ctrls[cell.serviceId] = TextEditingController(text: cell.currentReading?.newReading?.toStringAsFixed(0) ?? '');
    }
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.speed_outlined, color: AppColors.primary, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Ghi chỉ số - Phòng $roomNumber', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Kỳ: $_billingMonth', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
              ])),
            ]),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: SingleChildScrollView(child: Column(children: rowData.services.map((cell) {
                final approved = cell.currentReading?.status == 'APPROVED';
                final isElectric = cell.serviceName.toLowerCase().contains('điện');
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: approved ? AppColors.success.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: approved ? AppColors.success.withValues(alpha: 0.2) : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(isElectric ? Icons.bolt_rounded : Icons.water_drop_rounded, color: isElectric ? Colors.amber[800] : Colors.blue, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(cell.serviceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      if (approved) _statusBadge('APPROVED'),
                    ]),
                    const SizedBox(height: 8),
                    if (approved)
                      Text('Đã chốt: ${cell.currentReading?.newReading?.toStringAsFixed(0) ?? '-'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight))
                    else
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Đầu kỳ', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(8)), child: Text(cell.oldReading.toStringAsFixed(0), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight))),
                        ])),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Cuối kỳ *', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                          TextField(
                            controller: ctrls[cell.serviceId],
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: '> ${cell.oldReading.toStringAsFixed(0)}',
                              hintStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                              filled: true, fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                            ),
                          ),
                        ])),
                      ]),
                  ]),
                );
              }).toList())),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: TextButton(onPressed: () { Navigator.pop(ctx); for (final c in ctrls.values) c.dispose(); }, style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0)))), child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600)))),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  bool submitted = false;
                  for (final cell in rowData.services) {
                    if (cell.currentReading?.status == 'APPROVED') continue;
                    final val = double.tryParse(ctrls[cell.serviceId]?.text ?? '');
                    if (val == null) continue;
                    if (val < cell.oldReading) { _showSnack('Chỉ số ${cell.serviceName} phải >= đầu kỳ!'); return; }
                    submitted = true;
                    try { await MeterReadingService.submit(roomId: roomId, serviceId: cell.serviceId, billingMonth: '$_billingMonth-01', newReading: val); } catch (e) { if (mounted) _showSnack('Lỗi ${cell.serviceName}: $e'); }
                  }
                  for (final c in ctrls.values) c.dispose();
                  if (submitted) { _fetchData(); _showSnack('Đã lưu chỉ số!', success: true); } else { _showSnack('Vui lòng nhập ít nhất một chỉ số!'); }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Lưu tất cả', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showTinderModal() {
    final pending = _pendingItems;
    if (pending.isEmpty) return;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => _TinderReviewSheet(
        pendingItems: pending,
        onApprove: (id) async { await MeterReadingService.approve(id); },
        onReject: (id) async { await MeterReadingService.reject(id, reason: 'Chỉ số không hợp lệ'); },
        onDone: () { Navigator.pop(ctx); _fetchData(); },
        onShowImage: _showImageLightbox,
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color; String label;
    switch (status) {
      case 'APPROVED': color = AppColors.success; label = 'Đã duyệt'; break;
      case 'REJECTED': color = AppColors.danger; label = 'Từ chối'; break;
      case 'SUBMITTED': color = const Color(0xFF3B82F6); label = 'Đã nộp'; break;
      default: color = AppColors.warning; label = 'Chờ duyệt';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tableData = _tableData;
    final pendingItems = _pendingItems;
    final pendingCount = _pendingCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton(onPressed: _fetchData, backgroundColor: AppColors.primary, elevation: 2, child: const Icon(Icons.refresh_rounded, color: Colors.white)),
      body: Column(children: [
        // Controls bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (_motels.isNotEmpty) ...[
                Expanded(child: Container(
                  height: 40,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0)), color: Colors.white),
                  child: DropdownButtonHideUnderline(child: DropdownButton<int>(
                    isExpanded: true, value: _selectedMotelId,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    borderRadius: BorderRadius.circular(12),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
                    items: _motels.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) { if (v != null) { setState(() => _selectedMotelId = v); _fetchData(); } },
                  )),
                )),
                const SizedBox(width: 10),
              ],
              GestureDetector(
                onTap: _pickMonth,
                child: Container(
                  height: 40, padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0)), color: Colors.white),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.textSecondaryLight),
                    const SizedBox(width: 6),
                    Text(_billingMonth, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ]),
            if (pendingItems.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: _showTinderModal,
                  icon: const Icon(Icons.flash_on_rounded, size: 16),
                  label: const Text('Duyệt nhanh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary), padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton.icon(
                  onPressed: _bulkLoading ? null : _bulkApprove,
                  icon: _bulkLoading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.done_all_rounded, size: 16),
                  label: Text('Duyệt tất cả (${pendingItems.length})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                )),
              ]),
            ],
            if (pendingCount > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFDE68A))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFD97706)),
                  const SizedBox(width: 6),
                  Text('$pendingCount mục chưa chốt số', style: const TextStyle(fontSize: 12, color: Color(0xFFD97706), fontWeight: FontWeight.w600)),
                ]),
              ),
            ],
          ]),
        ),
        // Table
        Expanded(child: RefreshIndicator(
          onRefresh: _fetchData, color: AppColors.primary,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
              : _error != null ? _buildError()
              : tableData.isEmpty ? _buildEmpty()
              : ListView.builder(padding: const EdgeInsets.all(12), itemCount: tableData.length, itemBuilder: (_, i) => _buildRoomCard(tableData[i])),
        )),
      ]),
    );
  }

  Future<void> _pickMonth() async {
    final parts = _billingMonth.split('-');
    final picked = await showDialog<String>(context: context, builder: (ctx) => _MonthPickerDialog(initialYear: int.parse(parts[0]), initialMonth: int.parse(parts[1])));
    if (picked != null) { setState(() => _billingMonth = picked); _fetchData(); }
  }

  Widget _buildError() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
    const SizedBox(height: 12),
    Text(_error ?? '', style: const TextStyle(color: AppColors.danger)),
    const SizedBox(height: 12),
    ElevatedButton.icon(onPressed: _fetchData, icon: const Icon(Icons.refresh), label: const Text('Thử lại'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white)),
  ]));

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 70, height: 70, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle), child: const Icon(Icons.speed_outlined, size: 36, color: AppColors.primary)),
    const SizedBox(height: 16),
    const Text('Không có phòng hoặc dịch vụ đo đếm nào', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
    const SizedBox(height: 6),
    const Text('Chọn khu trọ hoặc kỳ khác để xem', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
  ]));

  Widget _buildRoomCard(_RoomRow row) {
    final hasPending = row.services.any((c) => c.currentReading == null || c.currentReading!.status == 'PENDING' || c.currentReading!.status == 'SUBMITTED');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFF1F5F9)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 10), child: Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text('Phòng ${row.roomNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary))),
          const Spacer(),
          if (hasPending) GestureDetector(
            onTap: () => _showSubmitReadingSheet(row.roomId, row.roomNumber),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)), child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.speed_outlined, size: 14, color: Colors.white), SizedBox(width: 5),
              Text('Ghi chỉ số', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
            ])),
          ),
        ])),
        Container(height: 1, color: const Color(0xFFF1F5F9)),
        ...row.services.map((cell) => _buildServiceRow(cell)),
      ]),
    );
  }

  Widget _buildServiceRow(_RoomServiceCell cell) {
    final cur = cell.currentReading;
    final isElectric = cell.serviceName.toLowerCase().contains('điện');
    return Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 30, height: 30, decoration: BoxDecoration(color: (isElectric ? Colors.amber : Colors.blue).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(isElectric ? Icons.bolt_rounded : Icons.water_drop_rounded, color: isElectric ? Colors.amber[800] : Colors.blue, size: 16)),
        const SizedBox(width: 10),
        Expanded(child: Text(cell.serviceName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        if (cur != null) _statusBadge(cur.status),
      ]),
      const SizedBox(height: 8),
      if (cur == null)
        const Text('Chưa ghi chỉ số', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight, fontStyle: FontStyle.italic))
      else ...[
        Row(children: [
          _infoChip('Đầu', cell.oldReading.toStringAsFixed(0), Colors.grey),
          const SizedBox(width: 6),
          _infoChip('Cuối', cur.newReading?.toStringAsFixed(0) ?? '-', AppColors.primary),
          const SizedBox(width: 6),
          _infoChip('≈${cur.consumption?.toStringAsFixed(0) ?? '0'}đv', '', AppColors.success),
          if (cur.imageUrl != null) ...[
            const Spacer(),
            GestureDetector(onTap: () => _showImageLightbox(cur.imageUrl!), child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.image_outlined, size: 16, color: AppColors.textSecondaryLight))),
          ],
        ]),
        if (cur.status == 'PENDING' || cur.status == 'SUBMITTED') ...[
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: () => _reject(cur.id), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), foregroundColor: AppColors.danger), child: const Text('Từ chối', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
            const SizedBox(width: 6),
            ElevatedButton(onPressed: () => _approve(cur.id), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4), elevation: 0, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Duyệt', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          ]),
        ],
      ],
    ]));
  }

  Widget _infoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
      child: Text(value.isEmpty ? label : '$label: $value', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tinder Review Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _TinderReviewSheet extends StatefulWidget {
  final List<_PendingItem> pendingItems;
  final Future<void> Function(int) onApprove;
  final Future<void> Function(int) onReject;
  final VoidCallback onDone;
  final void Function(String) onShowImage;
  const _TinderReviewSheet({required this.pendingItems, required this.onApprove, required this.onReject, required this.onDone, required this.onShowImage});

  @override
  State<_TinderReviewSheet> createState() => _TinderReviewSheetState();
}

class _TinderReviewSheetState extends State<_TinderReviewSheet> {
  int _index = 0;
  bool _acting = false;

  Future<void> _doApprove() async {
    if (_acting || _index >= widget.pendingItems.length) return;
    setState(() => _acting = true);
    await widget.onApprove(widget.pendingItems[_index].reading.id);
    if (mounted) setState(() { _index++; _acting = false; });
  }

  Future<void> _doReject() async {
    if (_acting || _index >= widget.pendingItems.length) return;
    setState(() => _acting = true);
    await widget.onReject(widget.pendingItems[_index].reading.id);
    if (mounted) setState(() { _index++; _acting = false; });
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.pendingItems.length;
    final done = _index >= total;
    final cur = done ? null : widget.pendingItems[_index];

    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.flash_on_rounded, color: AppColors.primary, size: 22)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Duyệt nhanh chỉ số', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Xem xét lần lượt từng chỉ số', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
          ])),
          if (!done) Text('${_index + 1} / $total', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ]),
        const SizedBox(height: 20),
        if (done) ...[
          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.success.withValues(alpha: 0.2))), child: const Column(children: [
            Icon(Icons.check_circle_outline_rounded, size: 52, color: AppColors.success),
            SizedBox(height: 12),
            Text('Hoàn thành!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            SizedBox(height: 6),
            Text('Không còn chỉ số nào cần xét duyệt.', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
          ])),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: widget.onDone, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold)))),
        ] else if (cur != null) ...[
          Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Phòng ${cur.roomNumber} – ${cur.serviceName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
            Text('Kỳ: ${cur.reading.billingMonth.length >= 7 ? cur.reading.billingMonth.substring(0, 7) : cur.reading.billingMonth}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
            const SizedBox(height: 12),
            if (cur.reading.imageUrl != null)
              GestureDetector(onTap: () => widget.onShowImage(cur.reading.imageUrl!), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(cur.reading.imageUrl!, height: 140, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 80, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(12)), child: const Center(child: Icon(Icons.broken_image, color: AppColors.textSecondaryLight))))))
            else
              Container(height: 80, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(12)), child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.image_not_supported_outlined, size: 28, color: AppColors.textSecondaryLight), SizedBox(height: 4), Text('Không có ảnh minh chứng', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight))]))),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _numCell('Đầu kỳ', cur.oldReading.toStringAsFixed(0), const Color(0xFF64748B))),
              const SizedBox(width: 8),
              Expanded(child: _numCell('Cuối kỳ', cur.reading.newReading?.toStringAsFixed(0) ?? '-', AppColors.primary)),
              const SizedBox(width: 8),
              Expanded(child: _numCell('Tiêu thụ', cur.reading.consumption?.toStringAsFixed(0) ?? '-', AppColors.success)),
            ]),
          ])),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: _acting ? null : _doReject, icon: const Icon(Icons.close_rounded, size: 18), label: const Text('Từ chối', style: TextStyle(fontWeight: FontWeight.bold)), style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(onPressed: _acting ? null : _doApprove, icon: const Icon(Icons.check_rounded, size: 18), label: const Text('Duyệt', style: TextStyle(fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
          ]),
          const SizedBox(height: 8),
          const Text('Xem xét từng mục rồi nhấn Duyệt hoặc Từ chối', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
        ],
      ]),
    );
  }

  Widget _numCell(String label, String value, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Text(label, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7))),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Month Picker Dialog
// ─────────────────────────────────────────────────────────────────────────────
class _MonthPickerDialog extends StatefulWidget {
  final int initialYear; final int initialMonth;
  const _MonthPickerDialog({required this.initialYear, required this.initialMonth});
  @override State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year; late int _month;
  @override void initState() { super.initState(); _year = widget.initialYear; _month = widget.initialMonth; }

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: const Text('Chọn kỳ', style: TextStyle(fontWeight: FontWeight.bold)),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(onPressed: () => setState(() => _year--), icon: const Icon(Icons.chevron_left_rounded)),
        Text('$_year', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        IconButton(onPressed: () => setState(() => _year++), icon: const Icon(Icons.chevron_right_rounded)),
      ]),
      const SizedBox(height: 10),
      GridView.count(crossAxisCount: 4, shrinkWrap: true, mainAxisSpacing: 6, crossAxisSpacing: 6, childAspectRatio: 1.5, children: List.generate(12, (i) {
        final m = i + 1; final sel = m == _month;
        return GestureDetector(onTap: () => setState(() => _month = m), child: Container(
          decoration: BoxDecoration(color: sel ? AppColors.primary : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text('T$m', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: sel ? Colors.white : const Color(0xFF475569)))),
        ));
      })),
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
      ElevatedButton(onPressed: () => Navigator.pop(context, '$_year-${_month.toString().padLeft(2, '0')}'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Chọn')),
    ],
  );
}
