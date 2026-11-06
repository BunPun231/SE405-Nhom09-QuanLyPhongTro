import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/motel_service.dart';
import '../../widgets/maintenance_widgets.dart';

/// Kho thiết bị (UC40–48): danh sách theo khu trọ, thêm/sửa/xóa, nhập kho, gán/thu hồi phòng,
/// gửi sửa, thanh lý và lịch sử biến động.
class ManagerDevicesScreen extends StatefulWidget {
  const ManagerDevicesScreen({Key? key}) : super(key: key);

  @override
  State<ManagerDevicesScreen> createState() => _ManagerDevicesScreenState();
}

class _ManagerDevicesScreenState extends State<ManagerDevicesScreen> {
  List<MotelResult> _motels = [];
  MotelResult? _motel;
  List<DeviceResult> _devices = [];
  String _query = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMotels();
  }

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');

  void _toast(String msg, {bool ok = false}) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: ok ? AppColors.success : null),
      );

  String _money(double? v) => v == null ? '—' : '${NumberFormat('#,###', 'vi').format(v)}đ';

  Future<void> _loadMotels() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await MotelService.list();
      _motels = res.content;
      if (_motels.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      _motel = _motels.first;
      await _loadDevices(showLoading: false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _msg(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDevices({bool showLoading = true}) async {
    if (_motel == null) return;
    if (showLoading) setState(() => _isLoading = true);
    try {
      final res = await DeviceService.list(_motel!.id);
      if (!mounted) return;
      setState(() {
        _devices = res.content;
        _error = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _msg(e);
        _isLoading = false;
      });
    }
  }

  List<DeviceResult> get _visible {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _devices;
    return _devices.where((d) => d.name.toLowerCase().contains(q) || (d.brand ?? '').toLowerCase().contains(q)).toList();
  }

  // ─── Thêm / sửa thiết bị ──────────────────────────────────────────────────

  void _showFormSheet({DeviceResult? editing}) {
    final nameCtrl = TextEditingController(text: editing?.name ?? '');
    final brandCtrl = TextEditingController(text: editing?.brand ?? '');
    final priceCtrl = TextEditingController(text: editing?.purchasePrice != null ? editing!.purchasePrice!.toStringAsFixed(0) : '');
    final qtyCtrl = TextEditingController(text: '1');
    DateTime? date = editing?.purchaseDate != null ? DateTime.tryParse(editing!.purchaseDate!) : null;
    var saving = false;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => _SheetShell(
          title: editing == null ? 'Thêm Thiết Bị' : 'Chỉnh Sửa Thiết Bị',
          subtitle: _motel?.name,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ErrorBanner(error),
              TextField(controller: nameCtrl, textCapitalization: TextCapitalization.sentences, decoration: maintenanceInputDecoration('Tên thiết bị *')),
              const SizedBox(height: 12),
              TextField(controller: brandCtrl, decoration: maintenanceInputDecoration('Hãng / Thương hiệu')),
              const SizedBox(height: 12),
              TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: maintenanceInputDecoration('Giá mua (đ)')),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: date ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setSheet(() => date = picked);
                },
                child: InputDecorator(
                  decoration: maintenanceInputDecoration('Ngày mua'),
                  child: Row(children: [
                    Expanded(child: Text(date == null ? 'Chưa chọn' : DateFormat('dd/MM/yyyy').format(date!), style: const TextStyle(fontSize: 14))),
                    const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondaryLight),
                  ]),
                ),
              ),
              if (editing == null) ...[
                const SizedBox(height: 12),
                TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: maintenanceInputDecoration('Số lượng nhập kho *')),
              ],
              const SizedBox(height: 20),
              _SubmitButton(
                label: editing == null ? 'Thêm thiết bị' : 'Lưu thay đổi',
                loading: saving,
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                  final price = double.tryParse(priceCtrl.text.trim().replaceAll(RegExp(r'[^0-9.]'), ''));
                  if (name.isEmpty) {
                    setSheet(() => error = 'Vui lòng nhập tên thiết bị');
                    return;
                  }
                  if (editing == null && qty < 1) {
                    setSheet(() => error = 'Số lượng phải từ 1 trở lên');
                    return;
                  }
                  setSheet(() {
                    saving = true;
                    error = null;
                  });
                  try {
                    final dateStr = date == null ? null : DateFormat('yyyy-MM-dd').format(date!);
                    if (editing == null) {
                      await DeviceService.create(_motel!.id,
                          name: name, brand: brandCtrl.text.trim(), purchasePrice: price, purchaseDate: dateStr, totalQuantity: qty);
                    } else {
                      await DeviceService.update(_motel!.id, editing.id,
                          name: name, brand: brandCtrl.text.trim(), purchasePrice: price, purchaseDate: dateStr);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    _toast(editing == null ? 'Đã thêm thiết bị' : 'Đã cập nhật thiết bị', ok: true);
                    _loadDevices(showLoading: false);
                  } catch (e) {
                    setSheet(() {
                      saving = false;
                      error = _msg(e);
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Thao tác kho ─────────────────────────────────────────────────────────

  /// Sheet nhập số lượng + ghi chú (và tùy chọn chọn phòng) cho một thao tác kho.
  void _showActionSheet({
    required String title,
    required String subtitle,
    required String confirmLabel,
    required Color color,
    required int maxQty,
    required String noteLabel,
    List<_RoomOption>? rooms,
    bool askCondition = false,
    required Future<void> Function(int qty, String note, _RoomOption? room, String condition) onSubmit,
  }) {
    var qty = 1;
    _RoomOption? room = rooms != null && rooms.isNotEmpty ? rooms.first : null;
    final noteCtrl = TextEditingController();
    final conditionCtrl = TextEditingController(text: 'Tốt');
    var saving = false;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        // Giới hạn số lượng: theo kho/đang dùng, và theo số phòng đang giữ khi thu hồi.
        var limit = maxQty;
        final roomMax = room?.maxQty;
        if (roomMax != null) limit = (maxQty > 0 && maxQty < roomMax) ? maxQty : roomMax;
        if (qty > limit && limit > 0) qty = limit;
        return _SheetShell(
          title: title,
          subtitle: subtitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ErrorBanner(error),
              if (rooms != null) ...[
                DropdownButtonFormField<_RoomOption>(
                  value: room,
                  isExpanded: true,
                  decoration: maintenanceInputDecoration('Phòng'),
                  items: rooms.map((r) => DropdownMenuItem(value: r, child: Text(r.label, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setSheet(() => room = v),
                ),
                const SizedBox(height: 12),
              ],
              Row(children: [
                const Text('Số lượng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text('(tối đa $limit)', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                const Spacer(),
                IconButton(onPressed: qty > 1 ? () => setSheet(() => qty--) : null, icon: const Icon(Icons.remove_circle_outline_rounded)),
                Text('$qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(onPressed: qty < limit ? () => setSheet(() => qty++) : null, icon: const Icon(Icons.add_circle_outline_rounded)),
              ]),
              if (askCondition) ...[
                const SizedBox(height: 4),
                TextField(controller: conditionCtrl, decoration: maintenanceInputDecoration('Tình trạng thiết bị')),
                const SizedBox(height: 12),
              ],
              TextField(controller: noteCtrl, maxLines: 2, decoration: maintenanceInputDecoration(noteLabel)),
              const SizedBox(height: 20),
              _SubmitButton(
                label: confirmLabel,
                color: color,
                loading: saving,
                onPressed: limit < 1
                    ? null
                    : () async {
                        setSheet(() {
                          saving = true;
                          error = null;
                        });
                        try {
                          await onSubmit(qty, noteCtrl.text.trim(), room, conditionCtrl.text.trim());
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          setSheet(() {
                            saving = false;
                            error = _msg(e);
                          });
                        }
                      },
              ),
            ],
          ),
        );
      }),
    );
  }

  Future<List<RoomResult>> _rooms() async => (await RoomService.list(_motel!.id)).content;

  Future<void> _assign(DeviceResult d) async {
    List<RoomResult> rooms;
    try {
      rooms = await _rooms();
    } catch (e) {
      _toast(_msg(e));
      return;
    }
    if (!mounted) return;
    if (rooms.isEmpty) {
      _toast('Khu trọ chưa có phòng nào để gán thiết bị');
      return;
    }
    _showActionSheet(
      title: 'Gán Thiết Bị Vào Phòng',
      subtitle: '${d.name} · còn ${d.availableQuantity} trong kho',
      confirmLabel: 'Xác nhận gán',
      color: AppColors.primary,
      maxQty: d.availableQuantity,
      noteLabel: 'Ghi chú (không bắt buộc)',
      askCondition: true,
      rooms: rooms.map((r) => _RoomOption(r.id, 'Phòng ${r.roomNumber} · Tầng ${r.floor}')).toList(),
      onSubmit: (qty, note, room, cond) async {
        await DeviceService.assign(_motel!.id, d.id, roomId: room!.id, quantity: qty, condition: cond, note: note);
        _toast('Đã gán $qty ${d.name} vào ${room.label.split(' · ').first}', ok: true);
        _loadDevices(showLoading: false);
      },
    );
  }

  Future<void> _recall(DeviceResult d) async {
    // Tìm các phòng đang giữ thiết bị này.
    List<_RoomOption> holding = [];
    try {
      final rooms = await _rooms();
      final usages = await Future.wait(rooms.map((r) async {
        try {
          return MapEntry(r, await DeviceService.byRoom(_motel!.id, r.id));
        } catch (_) {
          return MapEntry(r, <DeviceUsage>[]);
        }
      }));
      for (final e in usages) {
        for (final u in e.value) {
          if (u.deviceId == d.id && u.assignedQuantity > 0) {
            holding.add(_RoomOption(e.key.id, 'Phòng ${e.key.roomNumber} · đang giữ ${u.assignedQuantity}', maxQty: u.assignedQuantity));
          }
        }
      }
    } catch (e) {
      _toast(_msg(e));
      return;
    }
    if (!mounted) return;
    if (holding.isEmpty) {
      _toast('Chưa có phòng nào đang giữ thiết bị này');
      return;
    }
    _showActionSheet(
      title: 'Thu Hồi Thiết Bị',
      subtitle: d.name,
      confirmLabel: 'Xác nhận thu hồi',
      color: AppColors.warning,
      maxQty: d.inUseQuantity,
      noteLabel: 'Lý do thu hồi (không bắt buộc)',
      rooms: holding,
      onSubmit: (qty, note, room, _) async {
        await DeviceService.recall(_motel!.id, d.id, roomId: room!.id, quantity: qty, note: note);
        _toast('Đã thu hồi $qty ${d.name}', ok: true);
        _loadDevices(showLoading: false);
      },
    );
  }

  void _simpleAction(
    DeviceResult d, {
    required String title,
    required String confirm,
    required Color color,
    required int maxQty,
    required String noteLabel,
    required String success,
    required Future<void> Function(int qty, String note) run,
  }) {
    _showActionSheet(
      title: title,
      subtitle: d.name,
      confirmLabel: confirm,
      color: color,
      maxQty: maxQty,
      noteLabel: noteLabel,
      onSubmit: (qty, note, _, __) async {
        await run(qty, note);
        _toast(success, ok: true);
        _loadDevices(showLoading: false);
      },
    );
  }

  Future<void> _delete(DeviceResult d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa thiết bị?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('"${d.name}" sẽ bị xóa khỏi danh mục. Thiết bị đang gán ở phòng thì không xóa được.', style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await DeviceService.remove(_motel!.id, d.id);
      _toast('Đã xóa thiết bị', ok: true);
      _loadDevices(showLoading: false);
    } catch (e) {
      _toast(_msg(e));
    }
  }

  // ─── Chi tiết ─────────────────────────────────────────────────────────────

  void _showDetail(DeviceResult d) {
    Widget action(IconData icon, String label, Color color, VoidCallback? onTap) {
      return SizedBox(
        width: (MediaQuery.of(context).size.width - 40 - 10) / 2,
        child: OutlinedButton.icon(
          onPressed: onTap == null
              ? null
              : () {
                  Navigator.pop(context);
                  onTap();
                },
          icon: Icon(icon, size: 18),
          label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: onTap == null ? AppColors.borderLight : color.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(d.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if ((d.brand ?? '').isNotEmpty) Text(d.brand!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
              const SizedBox(height: 12),
              _infoRow('Giá mua', _money(d.purchasePrice)),
              _infoRow('Ngày mua', d.purchaseDate == null ? '—' : DateFormat('dd/MM/yyyy').format(DateTime.tryParse(d.purchaseDate!) ?? DateTime.now())),
              const SizedBox(height: 12),
              _StatRow(device: d),
              const SizedBox(height: 16),
              const Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(spacing: 10, runSpacing: 10, children: [
                action(Icons.add_box_outlined, 'Nhập thêm', AppColors.success, () => _simpleAction(
                      d,
                      title: 'Nhập Thêm Vào Kho',
                      confirm: 'Xác nhận nhập kho',
                      color: AppColors.success,
                      maxQty: 9999,
                      noteLabel: 'Ghi chú (không bắt buộc)',
                      success: 'Đã nhập thêm vào kho',
                      run: (q, n) => DeviceService.importStock(_motel!.id, d.id, quantity: q, note: n),
                    )),
                action(Icons.meeting_room_outlined, 'Gán vào phòng', AppColors.primary, d.availableQuantity > 0 ? () => _assign(d) : null),
                action(Icons.assignment_return_outlined, 'Thu hồi', AppColors.warning, d.inUseQuantity > 0 ? () => _recall(d) : null),
                action(Icons.build_outlined, 'Gửi sửa chữa', const Color(0xFF8B5CF6), d.availableQuantity > 0
                    ? () => _simpleAction(
                          d,
                          title: 'Gửi Sửa Chữa',
                          confirm: 'Xác nhận gửi sửa',
                          color: const Color(0xFF8B5CF6),
                          maxQty: d.availableQuantity,
                          noteLabel: 'Mô tả hư hỏng',
                          success: 'Đã chuyển sang trạng thái sửa chữa',
                          run: (q, n) => DeviceService.sendToRepair(_motel!.id, d.id, quantity: q, note: n),
                        )
                    : null),
                action(Icons.check_circle_outline_rounded, 'Sửa xong', AppColors.info, d.repairingQuantity > 0
                    ? () => _simpleAction(
                          d,
                          title: 'Sửa Xong, Nhập Lại Kho',
                          confirm: 'Xác nhận sửa xong',
                          color: AppColors.info,
                          maxQty: d.repairingQuantity,
                          noteLabel: 'Ghi chú (không bắt buộc)',
                          success: 'Đã nhập lại kho sau sửa chữa',
                          run: (q, n) => DeviceService.finishRepair(_motel!.id, d.id, quantity: q, note: n),
                        )
                    : null),
                action(Icons.delete_sweep_outlined, 'Thanh lý', AppColors.danger, d.availableQuantity > 0
                    ? () => _simpleAction(
                          d,
                          title: 'Thanh Lý / Hao Hụt',
                          confirm: 'Xác nhận thanh lý',
                          color: AppColors.danger,
                          maxQty: d.availableQuantity,
                          noteLabel: 'Lý do thanh lý',
                          success: 'Đã thanh lý thiết bị',
                          run: (q, n) => DeviceService.dispose(_motel!.id, d.id, quantity: q, reason: n),
                        )
                    : null),
                action(Icons.edit_outlined, 'Chỉnh sửa', AppColors.textPrimaryLight, () => _showFormSheet(editing: d)),
                action(Icons.delete_outline_rounded, 'Xóa', AppColors.danger, () => _delete(d)),
              ]),
              const SizedBox(height: 20),
              const Text('Lịch sử biến động', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              FutureBuilder<List<DeviceMovementLog>>(
                future: DeviceService.movementLogs(d.motelId, d.id),
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
                  }
                  final logs = snap.data ?? [];
                  if (snap.hasError || logs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('Chưa có biến động nào', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12))),
                    );
                  }
                  return Column(
                    children: logs
                        .map((l) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.swap_vert_rounded, color: AppColors.primary, size: 20),
                              title: Text('${l.actionLabel} · SL ${l.quantity}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                [
                                  if (l.timestamp != null) DateFormat('dd/MM/yyyy HH:mm').format(l.timestamp!.toLocal()),
                                  if ((l.note ?? '').isNotEmpty) l.note!,
                                ].join(' · '),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
      );

  // ─── Giao diện chính ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _motel == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showFormSheet(),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Thêm thiết bị', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
      body: RefreshIndicator(
        onRefresh: () => _motel == null ? _loadMotels() : _loadDevices(showLoading: false),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [
                    const SizedBox(height: 120),
                    Center(child: Text(_error!, style: const TextStyle(color: AppColors.danger))),
                    Center(child: TextButton(onPressed: _loadMotels, child: const Text('Thử lại'))),
                  ])
                : _motels.isEmpty
                    ? ListView(children: [_emptyState(Icons.business_outlined, 'Chưa có khu trọ nào', 'Hãy tạo khu trọ trước khi quản lý thiết bị')])
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                        children: [
                          const Text('Kho Thiết Bị', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${_devices.length} loại thiết bị', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                          const SizedBox(height: 12),
                          if (_motels.length > 1) ...[
                            DropdownButtonFormField<MotelResult>(
                              value: _motel,
                              isExpanded: true,
                              decoration: maintenanceInputDecoration('Khu trọ'),
                              items: _motels.map((m) => DropdownMenuItem(value: m, child: Text(m.name, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (m) {
                                if (m == null) return;
                                setState(() => _motel = m);
                                _loadDevices();
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextField(
                            onChanged: (v) => setState(() => _query = v),
                            decoration: InputDecoration(
                              hintText: 'Tìm theo tên hoặc hãng...',
                              prefixIcon: const Icon(Icons.search_rounded),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_visible.isEmpty)
                            _emptyState(
                              Icons.memory_outlined,
                              _devices.isEmpty ? 'Chưa có thiết bị nào' : 'Không tìm thấy thiết bị',
                              _devices.isEmpty ? 'Nhấn "Thêm thiết bị" để nhập kho thiết bị, vật tư' : 'Thử từ khóa khác',
                            ),
                          ..._visible.map(_buildCard),
                        ],
                      ),
      ),
    );
  }

  Widget _buildCard(DeviceResult d) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(d),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.memory_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                    Text(
                      [if ((d.brand ?? '').isNotEmpty) d.brand!, _money(d.purchasePrice)].join(' · '),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                    ),
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight),
              ]),
              const SizedBox(height: 12),
              _StatRow(device: d),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: Icon(icon, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
        ]),
      );
}

// ─── Thành phần dùng riêng cho màn này ──────────────────────────────────────

class _RoomOption {
  final int id;
  final String label;
  final int? maxQty;
  _RoomOption(this.id, this.label, {this.maxQty});
}

class _StatRow extends StatelessWidget {
  final DeviceResult device;
  const _StatRow({required this.device});

  Widget _stat(String label, int value, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            Text('$value', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _stat('Tổng', device.totalQuantity, AppColors.primary),
      const SizedBox(width: 8),
      _stat('Sẵn có', device.availableQuantity, AppColors.success),
      const SizedBox(width: 8),
      _stat('Đang dùng', device.inUseQuantity, AppColors.info),
      const SizedBox(width: 8),
      _stat('Đang sửa', device.repairingQuantity, AppColors.warning),
    ]);
  }
}

class _SheetShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const _SheetShell({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
              ],
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String? message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(message!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final bool loading;
  final Color color;
  final VoidCallback? onPressed;

  const _SubmitButton({required this.label, required this.loading, this.color = AppColors.primary, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }
}
