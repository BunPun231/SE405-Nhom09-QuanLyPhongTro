import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/motel_service.dart';

class ManagerRoomsScreen extends StatefulWidget {
  const ManagerRoomsScreen({Key? key}) : super(key: key);

  @override
  State<ManagerRoomsScreen> createState() => _ManagerRoomsScreenState();
}

class _ManagerRoomsScreenState extends State<ManagerRoomsScreen> {
  List<MotelResult> _motels = [];
  MotelResult? _selectedMotel;
  List<RoomResult> _rooms = [];
  bool _isLoading = true;
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadMotelsAndRooms();
  }

  Future<void> _loadMotelsAndRooms() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final motelRes = await MotelService.list();
      if (!mounted) return;
      _motels = motelRes.content;
      if (_motels.isNotEmpty) {
        // Keep current selected motel if still exists
        final stillExists = _motels.any((m) => m.id == _selectedMotel?.id);
        _selectedMotel = stillExists ? _motels.firstWhere((m) => m.id == _selectedMotel!.id) : _motels.first;
        final roomRes = await RoomService.list(_selectedMotel!.id);
        if (!mounted) return;
        _rooms = roomRes.content;
      } else {
        _selectedMotel = null;
        _rooms = [];
      }
    } catch (e) {
      debugPrint('Error loading rooms: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRoomsForMotel(MotelResult motel) async {
    if (!mounted) return;
    setState(() {
      _selectedMotel = motel;
      _isLoading = true;
    });
    try {
      final roomRes = await RoomService.list(motel.id);
      if (mounted) {
        setState(() {
          _rooms = roomRes.content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MODAL: Chi tiết & Sửa / Xóa / Đổi trạng thái phòng (tương ứng RoomDetailModal)
  // ─────────────────────────────────────────────────────────────────────────────
  void _showRoomDetailSheet(RoomResult room) {
    String currentStatus = room.status;
    bool isEditing = false;
    final editRoomNumCtrl = TextEditingController(text: room.roomNumber);
    final editFloorCtrl = TextEditingController(text: room.floor.toString());
    final editAreaCtrl = TextEditingController(text: room.area?.toString() ?? '');
    final editPriceCtrl = TextEditingController(text: room.basePrice.toStringAsFixed(0));
    final editDescCtrl = TextEditingController(text: room.description ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (bottomSheetContext, setModalState) {
          final priceFormatted = room.basePrice.toStringAsFixed(0).replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header: Room Number + Edit Toggle + Delete
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.meeting_room_rounded, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Phòng ${room.roomNumber}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                              ),
                              Text(
                                '${_selectedMotel?.name ?? ''} • Tầng ${room.floor}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => setModalState(() => isEditing = !isEditing),
                          icon: Icon(
                            isEditing ? Icons.close_rounded : Icons.edit_outlined,
                            color: isEditing ? AppColors.danger : AppColors.primary,
                            size: 20,
                          ),
                          tooltip: isEditing ? 'Hủy sửa' : 'Chỉnh sửa',
                        ),
                        IconButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: bottomSheetContext,
                              builder: (dCtx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: const Text('Xóa phòng trọ?'),
                                content: Text('Bạn có chắc muốn xóa phòng ${room.roomNumber}? Thao tác này không thể hoàn tác.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dCtx, false),
                                    child: const Text('Hủy'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(dCtx, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                                    child: const Text('Xóa vĩnh viễn', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              try {
                                await RoomService.delete(_selectedMotel!.id, room.hashid);
                                if (!bottomSheetContext.mounted) return;
                                Navigator.pop(bottomSheetContext);
                                if (_selectedMotel != null) _loadRoomsForMotel(_selectedMotel!);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Đã xóa phòng ${room.roomNumber}'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                          tooltip: 'Xóa phòng',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Dropdown đổi trạng thái (UC30)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.sync_alt_rounded, size: 18, color: AppColors.textSecondaryLight),
                          const SizedBox(width: 10),
                          const Text(
                            'Trạng thái:',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: ['AVAILABLE', 'RENTED', 'DEPOSITED', 'REPAIRING', 'OUT_OF_BUSINESS']
                                        .contains(currentStatus)
                                    ? currentStatus
                                    : 'AVAILABLE',
                                isDense: true,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                onChanged: room.status == 'RENTED'
                                    ? null // Web quy định không tự đổi nếu đang thuê
                                    : (val) async {
                                        if (val == null || val == currentStatus) return;
                                        setModalState(() => currentStatus = val);
                                        try {
                                          await RoomService.updateStatus(
                                            _selectedMotel!.id,
                                            room.hashid,
                                            val,
                                          );
                                          if (_selectedMotel != null) _loadRoomsForMotel(_selectedMotel!);
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Cập nhật trạng thái thành công!'),
                                                backgroundColor: AppColors.success,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          setModalState(() => currentStatus = room.status);
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
                                            );
                                          }
                                        }
                                      },
                                items: const [
                                  DropdownMenuItem(value: 'AVAILABLE', child: Text('Trống', overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: 'RENTED', enabled: false, child: Text('Đang thuê', overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: 'DEPOSITED', child: Text('Đặt cọc', overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: 'REPAIRING', child: Text('Sửa chữa', overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: 'OUT_OF_BUSINESS', child: Text('Ngừng h/đ', overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (isEditing) ...[
                      // Form Chỉnh sửa thông tin phòng (UC29)
                      _buildLabel('Số phòng / Tên phòng'),
                      const SizedBox(height: 6),
                      _buildTextField(editRoomNumCtrl, 'Ví dụ: 101, A205', Icons.door_front_door_outlined),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Tầng'),
                                const SizedBox(height: 6),
                                _buildTextField(editFloorCtrl, '1', Icons.layers_rounded, inputType: TextInputType.number),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Diện tích (m²)'),
                                const SizedBox(height: 6),
                                _buildTextField(editAreaCtrl, '25', Icons.square_foot_rounded, inputType: TextInputType.number),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      _buildLabel('Giá thuê (VNĐ/tháng)'),
                      const SizedBox(height: 6),
                      _buildTextField(editPriceCtrl, '3500000', Icons.payments_outlined, inputType: TextInputType.number),
                      const SizedBox(height: 14),

                      _buildLabel('Ghi chú / Mô tả'),
                      const SizedBox(height: 6),
                      _buildTextField(editDescCtrl, 'Mô tả tiện ích, vị trí...', Icons.description_outlined),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => setModalState(() => isEditing = false),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                              child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (editRoomNumCtrl.text.trim().isEmpty) return;
                                try {
                                  await RoomService.update(
                                    _selectedMotel!.id,
                                    room.hashid,
                                    {
                                      'roomNumber': editRoomNumCtrl.text.trim(),
                                      'floor': int.tryParse(editFloorCtrl.text) ?? room.floor,
                                      'area': double.tryParse(editAreaCtrl.text),
                                      'basePrice': double.tryParse(editPriceCtrl.text) ?? room.basePrice,
                                      'description': editDescCtrl.text.trim().isEmpty ? null : editDescCtrl.text.trim(),
                                    },
                                  );
                                  if (!bottomSheetContext.mounted) return;
                                  Navigator.pop(bottomSheetContext);
                                  if (_selectedMotel != null) _loadRoomsForMotel(_selectedMotel!);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Đã cập nhật thông tin phòng thành công!'),
                                        backgroundColor: AppColors.success,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('Lưu thay đổi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // View Mode chi tiết
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow('Tầng', 'Tầng ${room.floor}'),
                            const Divider(height: 20, color: Color(0xFFE2E8F0)),
                            _buildInfoRow('Diện tích', room.area != null ? '${room.area} m²' : '—'),
                            const Divider(height: 20, color: Color(0xFFE2E8F0)),
                            _buildInfoRow('Giá thuê', '$priceFormatted đ/tháng', valueColor: AppColors.primary, isBold: true),
                            const Divider(height: 20, color: Color(0xFFE2E8F0)),
                            _buildInfoRow('Số người đang ở', '${room.currentResidentsCount} người'),
                            if (room.description != null && room.description!.isNotEmpty) ...[
                              const Divider(height: 20, color: Color(0xFFE2E8F0)),
                              _buildInfoRow('Ghi chú', room.description!),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Thông tin hợp đồng thuê
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (room.status == 'RENTED' ? AppColors.success : AppColors.warning).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    room.status == 'RENTED' ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                                    size: 18,
                                    color: room.status == 'RENTED' ? AppColors.success : AppColors.warning,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      room.status == 'RENTED' ? 'Đang có khách thuê' : 'Chưa có hợp đồng thuê',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                                    ),
                                    Text(
                                      '${room.currentResidentsCount} người cư trú',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(bottomSheetContext);
                                // Có thể chuyển sang tab hợp đồng
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Xem hợp đồng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MODAL: Thêm 1 phòng đơn lẻ
  // ─────────────────────────────────────────────────────────────────────────────
  void _showAddRoomSheet() {
    if (_selectedMotel == null) {
      _showWarningSnackBar('Vui lòng chọn hoặc tạo dãy trọ trước!');
      return;
    }

    final roomNumCtrl = TextEditingController();
    final floorCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController(text: '3500000');
    final areaCtrl = TextEditingController(text: '25');
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
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
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.meeting_room_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Thêm phòng mới', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                      Text(_selectedMotel!.name, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildLabel('Số phòng / Tên phòng'),
              const SizedBox(height: 8),
              _buildTextField(roomNumCtrl, 'Ví dụ: P101, A205...', Icons.door_front_door_outlined),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Tầng'),
                        const SizedBox(height: 8),
                        _buildTextField(floorCtrl, '1', Icons.layers_rounded, inputType: TextInputType.number),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Diện tích (m²)'),
                        const SizedBox(height: 8),
                        _buildTextField(areaCtrl, '25', Icons.square_foot_rounded, inputType: TextInputType.number),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildLabel('Giá thuê (VNĐ/tháng)'),
              const SizedBox(height: 8),
              _buildTextField(priceCtrl, '3500000', Icons.payments_outlined, inputType: TextInputType.number),
              const SizedBox(height: 16),

              _buildLabel('Ghi chú (Tùy chọn)'),
              const SizedBox(height: 8),
              _buildTextField(descCtrl, 'Ví dụ: Ban công thoáng, có gác lửng...', Icons.description_outlined),
              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (roomNumCtrl.text.trim().isEmpty) return;
                        Navigator.pop(ctx);
                        try {
                          await RoomService.create(
                            _selectedMotel!.id,
                            roomNumber: roomNumCtrl.text.trim(),
                            floor: int.tryParse(floorCtrl.text) ?? 1,
                            basePrice: double.tryParse(priceCtrl.text) ?? 3000000,
                            area: double.tryParse(areaCtrl.text),
                            description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                          );
                          _loadRoomsForMotel(_selectedMotel!);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Đã tạo phòng thành công!'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Tạo phòng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MODAL: Tạo phòng hàng loạt (tương ứng BulkAddRoomModal của Web FE)
  // ─────────────────────────────────────────────────────────────────────────────
  void _showBulkAddRoomSheet() {
    if (_selectedMotel == null) {
      _showWarningSnackBar('Vui lòng chọn hoặc tạo dãy trọ trước!');
      return;
    }

    final fromFloorCtrl = TextEditingController(text: '1');
    final toFloorCtrl = TextEditingController(text: (_selectedMotel!.totalFloors).toString());
    final countPerFloorCtrl = TextEditingController(text: '5');
    final basePriceCtrl = TextEditingController(text: '3500000');
    final areaCtrl = TextEditingController(text: '25');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (bulkCtx, setBulkState) {
          final startFloor = int.tryParse(fromFloorCtrl.text) ?? 1;
          final endFloor = int.tryParse(toFloorCtrl.text) ?? startFloor;
          final count = int.tryParse(countPerFloorCtrl.text) ?? 5;
          final totalPreviewCount = (endFloor >= startFloor && count > 0) ? (endFloor - startFloor + 1) * count : 0;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(bulkCtx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
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
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.layers_rounded, color: Color(0xFF6366F1), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tạo phòng hàng loạt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                              Text(_selectedMotel!.name, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Floor Range
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Từ tầng'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                fromFloorCtrl,
                                '1',
                                Icons.stairs_rounded,
                                inputType: TextInputType.number,
                                onChanged: (_) => setBulkState(() {}),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Đến tầng'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                toFloorCtrl,
                                '3',
                                Icons.stairs_rounded,
                                inputType: TextInputType.number,
                                onChanged: (_) => setBulkState(() {}),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Số phòng mỗi tầng'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      countPerFloorCtrl,
                      '5',
                      Icons.format_list_numbered_rounded,
                      inputType: TextInputType.number,
                      onChanged: (_) => setBulkState(() {}),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Diện tích chung (m²)'),
                              const SizedBox(height: 8),
                              _buildTextField(areaCtrl, '25', Icons.square_foot_rounded, inputType: TextInputType.number),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Giá thuê chung'),
                              const SizedBox(height: 8),
                              _buildTextField(basePriceCtrl, '3500000', Icons.payments_outlined, inputType: TextInputType.number),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Preview badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFF4F46E5), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Dự kiến tạo: $totalPreviewCount phòng (ví dụ: P101, P102... P$endFloor${count.toString().padLeft(2, '0')})',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3730A3)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(bulkCtx),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () async {
                              final fStart = int.tryParse(fromFloorCtrl.text) ?? 1;
                              final fEnd = int.tryParse(toFloorCtrl.text) ?? 1;
                              final fCount = int.tryParse(countPerFloorCtrl.text) ?? 0;
                              final price = double.tryParse(basePriceCtrl.text) ?? 0;
                              final area = double.tryParse(areaCtrl.text);

                              if (fStart <= 0 || fEnd < fStart || fCount <= 0) {
                                _showWarningSnackBar('Vui lòng nhập dải tầng và số phòng hợp lệ');
                                return;
                              }

                              Navigator.pop(bulkCtx);

                              try {
                                final List<Map<String, dynamic>> roomsToCreate = [];
                                for (int f = fStart; f <= fEnd; f++) {
                                  // Tính suffix tiếp theo dựa trên các phòng đang có
                                  int startSuffix = 1;
                                  final floorRooms = _rooms.where((r) => r.floor == f).toList();
                                  if (floorRooms.isNotEmpty) {
                                    final suffixes = floorRooms.map((r) {
                                      final cleanNum = r.roomNumber.replaceAll(RegExp(r'^[a-zA-Z\s]*'), '');
                                      final fStr = f.toString();
                                      if (cleanNum.startsWith(fStr)) {
                                        final suffix = int.tryParse(cleanNum.substring(fStr.length)) ?? 0;
                                        return suffix;
                                      }
                                      return int.tryParse(cleanNum) ?? 0;
                                    }).toList();
                                    startSuffix = suffixes.reduce((max, s) => s > max ? s : max) + 1;
                                  }

                                  for (int r = startSuffix; r < startSuffix + fCount; r++) {
                                    final roomNumber = 'P$f${r.toString().padLeft(2, '0')}';
                                    roomsToCreate.add({
                                      'floor': f,
                                      'roomNumber': roomNumber,
                                      'basePrice': price,
                                      if (area != null) 'area': area,
                                    });
                                  }
                                }

                                await RoomService.createBulk(_selectedMotel!.id, roomsToCreate);
                                if (_selectedMotel != null) _loadRoomsForMotel(_selectedMotel!);

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Đã tạo thành công ${roomsToCreate.length} phòng!'),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Tạo ngay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildLabel(String text) =>
      Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)));

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType inputType = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: inputType,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
        prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondaryLight),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredRooms = _rooms.where((r) {
      if (_selectedFilter == 'ALL') return true;
      if (_selectedFilter == 'RENTED') return r.status == 'RENTED';
      if (_selectedFilter == 'AVAILABLE') return r.status == 'AVAILABLE' || r.status == 'EMPTY';
      if (_selectedFilter == 'DEPOSITED') return r.status == 'DEPOSITED';
      if (_selectedFilter == 'REPAIRING') return r.status == 'REPAIRING';
      return true;
    }).toList();

    // Group rooms by floor (như Web FE: floors.map)
    final floors = filteredRooms.map((r) => r.floor).toSet().toList()..sort();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'bulkAddRoomBtn',
            onPressed: _showBulkAddRoomSheet,
            backgroundColor: const Color(0xFF4F46E5),
            elevation: 2,
            tooltip: 'Tạo phòng hàng loạt',
            child: const Icon(Icons.layers_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'singleAddRoomBtn',
            onPressed: _showAddRoomSheet,
            backgroundColor: AppColors.primary,
            elevation: 3,
            tooltip: 'Thêm phòng mới',
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ],
      ),
      body: Column(
        children: [
          // Motel Tabs bar (tương ứng dãy tabs trên Web FE)
          if (_motels.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _motels.map((motel) {
                    final isSelected = motel.id == _selectedMotel?.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _loadRoomsForMotel(motel),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.apartment_rounded,
                                size: 14,
                                color: isSelected ? Colors.white : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                motel.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // Filters status bar (như Web FE: Tất cả, Đang ở, Trống, Đặt cọc, Bảo trì)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                _filterChip('Tất cả (${_rooms.length})', 'ALL'),
                _filterChip('Đang ở (${_rooms.where((r) => r.status == 'RENTED').length})', 'RENTED'),
                _filterChip('Trống (${_rooms.where((r) => r.status == 'AVAILABLE' || r.status == 'EMPTY').length})', 'AVAILABLE'),
                _filterChip('Đặt cọc (${_rooms.where((r) => r.status == 'DEPOSITED').length})', 'DEPOSITED'),
                _filterChip('Bảo trì (${_rooms.where((r) => r.status == 'REPAIRING').length})', 'REPAIRING'),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (_selectedMotel != null) await _loadRoomsForMotel(_selectedMotel!);
              },
              color: AppColors.primary,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                  : filteredRooms.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: floors.length,
                          itemBuilder: (context, floorIndex) {
                            final floor = floors[floorIndex];
                            final roomsOnFloor = filteredRooms.where((r) => r.floor == floor).toList();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Floor header bar (tương ứng Tầng X • N phòng)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Tầng $floor',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${roomsOnFloor.length} phòng',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                                      ),
                                    ],
                                  ),
                                ),
                                // List phòng trên tầng
                                ...roomsOnFloor.map((room) => _buildRoomCard(room)),
                              ],
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: const Icon(Icons.meeting_room_outlined, size: 38, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text('Chưa có phòng nào', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 8),
            const Text('Tạo từng phòng hoặc bấm tạo hàng loạt\nđể chuẩn bị phòng nhanh chóng',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight, height: 1.5)),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: _showBulkAddRoomSheet,
                  icon: const Icon(Icons.layers_rounded, size: 16),
                  label: const Text('Tạo hàng loạt'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddRoomSheet,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Thêm 1 phòng'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
            boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))] : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(Icons.check_rounded, size: 13, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.textSecondaryLight)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomCard(RoomResult r) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (r.status == 'RENTED') {
      statusColor = AppColors.success;
      statusLabel = 'Đang thuê';
      statusIcon = Icons.person_rounded;
    } else if (r.status == 'AVAILABLE' || r.status == 'EMPTY') {
      statusColor = const Color(0xFF10B981);
      statusLabel = 'Trống';
      statusIcon = Icons.lock_open_rounded;
    } else if (r.status == 'DEPOSITED') {
      statusColor = const Color(0xFF8B5CF6);
      statusLabel = 'Đặt cọc';
      statusIcon = Icons.bookmark_added_rounded;
    } else if (r.status == 'REPAIRING') {
      statusColor = AppColors.warning;
      statusLabel = 'Sửa chữa';
      statusIcon = Icons.build_rounded;
    } else {
      statusColor = const Color(0xFF94A3B8);
      statusLabel = 'Ngừng h/đ';
      statusIcon = Icons.block_rounded;
    }

    final priceStr = r.basePrice.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showRoomDetailSheet(r),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.meeting_room_rounded, color: statusColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Phòng ${r.roomNumber}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                          const SizedBox(height: 2),
                          Text(
                            'Tầng ${r.floor}${r.area != null ? "  ·  ${r.area}m²" : ""}  ·  ${r.currentResidentsCount} người',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 11, color: statusColor),
                          const SizedBox(width: 4),
                          Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(height: 1, color: const Color(0xFFF1F5F9)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.payments_outlined, size: 13, color: AppColors.textSecondaryLight),
                        const SizedBox(width: 4),
                        Text(
                          '$priceStrđ/tháng',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    const Row(
                      children: [
                        Text('Chi tiết & sửa', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        SizedBox(width: 2),
                        Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.primary),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
