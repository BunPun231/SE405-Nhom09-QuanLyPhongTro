import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/motel_service.dart';
import '../../../core/services/service_service.dart';

class ManagerServicesScreen extends StatefulWidget {
  const ManagerServicesScreen({Key? key}) : super(key: key);

  @override
  State<ManagerServicesScreen> createState() => _ManagerServicesScreenState();
}

class _ManagerServicesScreenState extends State<ManagerServicesScreen> {
  List<MotelResult> _motels = [];
  MotelResult? _selectedMotel;
  List<ServiceResult> _services = [];
  bool _isLoading = true;

  static const Map<String, String> _chargeTypeLabel = {
    'FIXED': 'Cố định',
    'PER_PERSON': 'Theo người',
    'PER_INDEX': 'Theo chỉ số bậc thang',
    'PER_QUANTITY': 'Theo số lượng',
    'METERED': 'Theo chỉ số (cố định)',
    'TIERED': 'Bậc thang',
  };

  @override
  void initState() {
    super.initState();
    _loadMotelsAndServices();
  }

  Future<void> _loadMotelsAndServices() async {
    setState(() => _isLoading = true);
    try {
      final motelRes = await MotelService.list();
      _motels = motelRes.content;
      if (_motels.isNotEmpty) {
        _selectedMotel = _motels.first;
        _services = await ServiceService.list(_selectedMotel!.id);
      }
    } catch (e) {
      debugPrint('Error loading services: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadServicesForMotel(MotelResult motel) async {
    setState(() {
      _selectedMotel = motel;
      _isLoading = true;
    });
    try {
      final services = await ServiceService.list(motel.id);
      if (mounted) {
        setState(() {
          _services = services;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showServiceFormSheet(),
        backgroundColor: AppColors.primary,
        elevation: 2,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          // Motel Selector bar
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
                        onTap: () {
                          if (!isSelected) _loadServicesForMotel(motel);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
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
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.white : const Color(0xFF334155),
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

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (_selectedMotel != null) await _loadServicesForMotel(_selectedMotel!);
              },
              color: AppColors.primary,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                  : _services.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 70, height: 70,
                                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
                                child: const Icon(Icons.design_services_outlined, size: 36, color: AppColors.primary),
                              ),
                              const SizedBox(height: 16),
                              const Text('Chưa cấu hình dịch vụ nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              const SizedBox(height: 6),
                              const Text('Mặc định bao gồm Tiền điện, Tiền nước, Wifi, Rác...', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                          itemCount: _services.length,
                          itemBuilder: (context, index) => _buildServiceCard(_services[index]),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(ServiceResult s) {
    final isTiered = s.chargeType == 'PER_INDEX' || (s.pricingTiers != null && s.pricingTiers!.isNotEmpty);
    final isElectric = s.name.toLowerCase().contains('điện');
    final isWater = s.name.toLowerCase().contains('nước');

    Color iconBg = AppColors.primary.withValues(alpha: 0.1);
    Color iconColor = AppColors.primary;
    IconData icon = Icons.design_services_rounded;

    if (isElectric) {
      iconBg = Colors.amber.withValues(alpha: 0.12);
      iconColor = Colors.amber[800]!;
      icon = Icons.bolt_rounded;
    } else if (isWater) {
      iconBg = Colors.blue.withValues(alpha: 0.12);
      iconColor = Colors.blue;
      icon = Icons.water_drop_rounded;
    }

    final priceStr = (s.basePrice ?? 0).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                          if (s.mandatory) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                              child: const Text('Bắt buộc', style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _chargeTypeLabel[s.chargeType] ?? s.chargeType,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
                if (!isTiered)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${priceStr}đ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                      Text('/${s.unit ?? 'đơn vị'}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                    ],
                  ),
              ],
            ),

            if (isTiered && s.pricingTiers != null && s.pricingTiers!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bậc thang tính tiền điện / nước:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    ...s.pricingTiers!.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final t = entry.value;
                      final endStr = t.tierEnd != null && t.tierEnd! > 0 ? '${t.tierEnd!.toStringAsFixed(0)} ${s.unit ?? ''}' : 'trở lên';
                      final pStr = t.pricePerUnit.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Bậc ${idx + 1}: ${t.tierStart?.toStringAsFixed(0) ?? '0'} - $endStr', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            Text('$pStr đ/${s.unit ?? 'đv'}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            Container(height: 1, color: const Color(0xFFF1F5F9)),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showAssignRoomsSheet(s),
                  icon: const Icon(Icons.meeting_room_outlined, size: 14),
                  label: const Text('Áp dụng phòng', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
                TextButton.icon(
                  onPressed: () => _showServiceFormSheet(editing: s),
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Sửa', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.textSecondaryLight),
                ),
                TextButton.icon(
                  onPressed: () => _deleteService(s),
                  icon: const Icon(Icons.delete_outline_rounded, size: 14),
                  label: const Text('Xóa', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _deleteService(ServiceResult s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa dịch vụ'),
        content: Text('Bạn có chắc muốn xóa dịch vụ "${s.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && _selectedMotel != null) {
      try {
        await ServiceService.delete(_selectedMotel!.id, s.id);
        _loadServicesForMotel(_selectedMotel!);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  void _showAssignRoomsSheet(ServiceResult s) async {
    if (_selectedMotel == null) return;
    List<RoomResult> rooms = [];
    List<int> assignedRoomIds = [];

    try {
      final roomRes = await RoomService.list(_selectedMotel!.id);
      rooms = roomRes.content;
      final futures = rooms.map((r) async {
        try {
          final svcs = await ServiceService.listByRoom(_selectedMotel!.id, r.hashid);
          if (svcs.any((x) => x.id == s.id)) {
            return r.id;
          }
        } catch (_) {}
        return null;
      });
      final results = await Future.wait(futures);
      assignedRoomIds = results.whereType<int>().toList();
    } catch (_) {}

    if (!mounted) return;

    final selected = Set<int>.from(assignedRoomIds);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
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
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Áp dụng dịch vụ: ${s.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  Text('${selected.length}/${rooms.length} phòng', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => setSheetState(() => selected.addAll(rooms.map((r) => r.id))),
                    child: const Text('Chọn tất cả', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => setSheetState(() => selected.clear()),
                    child: const Text('Bỏ chọn', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final r = rooms[index];
                    final isChecked = selected.contains(r.id);
                    return CheckboxListTile(
                      value: isChecked,
                      title: Text('Phòng ${r.roomNumber} (Tầng ${r.floor})', style: const TextStyle(fontSize: 14)),
                      onChanged: (val) {
                        setSheetState(() {
                          if (val == true) {
                            selected.add(r.id);
                          } else {
                            selected.remove(r.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await ServiceService.assignToRooms(_selectedMotel!.id, s.id, selected.toList());
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật phòng áp dụng!')));
                      }
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
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
        ),
      ),
    );
  }

  void _showServiceFormSheet({ServiceResult? editing}) {
    if (_selectedMotel == null) return;

    final nameCtrl = TextEditingController(text: editing?.name ?? '');
    String chargeType = editing?.chargeType ?? 'FIXED';
    final unitCtrl = TextEditingController(text: editing?.unit ?? '');
    final priceCtrl = TextEditingController(text: (editing?.basePrice ?? 0).toStringAsFixed(0));
    bool mandatory = editing?.mandatory ?? false;

    // Tiers
    List<Map<String, TextEditingController>> tierCtrls = [];
    if (editing?.pricingTiers != null && editing!.pricingTiers!.isNotEmpty) {
      for (var t in editing.pricingTiers!) {
        tierCtrls.add({
          'start': TextEditingController(text: (t.tierStart ?? 0).toStringAsFixed(0)),
          'end': TextEditingController(text: (t.tierEnd ?? 0).toStringAsFixed(0)),
          'price': TextEditingController(text: t.pricePerUnit.toStringAsFixed(0)),
        });
      }
    } else if (chargeType == 'PER_INDEX') {
      tierCtrls = [
        {'start': TextEditingController(text: '0'), 'end': TextEditingController(text: '50'), 'price': TextEditingController(text: '2000')},
        {'start': TextEditingController(text: '51'), 'end': TextEditingController(text: '100'), 'price': TextEditingController(text: '2500')},
        {'start': TextEditingController(text: '101'), 'end': TextEditingController(text: '0'), 'price': TextEditingController(text: '3000')},
      ];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isTiered = chargeType == 'PER_INDEX';

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                        width: 40, height: 4,
                        decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.design_services_rounded, color: AppColors.primary, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                editing != null ? 'Cập Nhật Dịch Vụ' : 'Thêm Dịch Vụ Mới',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                              if (_selectedMotel != null)
                                Text(
                                  'Khu: ${_selectedMotel!.name}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Quick suggestions for Electric/Water
                    const Text('Gợi ý dịch vụ nhanh:', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _suggestionChip('Điện (Bậc thang)', () {
                            setSheetState(() {
                              nameCtrl.text = 'Điện';
                              chargeType = 'PER_INDEX';
                              unitCtrl.text = 'kWh';
                              mandatory = true;
                              if (tierCtrls.isEmpty) {
                                tierCtrls = [
                                  {'start': TextEditingController(text: '0'), 'end': TextEditingController(text: '50'), 'price': TextEditingController(text: '2000')},
                                  {'start': TextEditingController(text: '51'), 'end': TextEditingController(text: '100'), 'price': TextEditingController(text: '2500')},
                                  {'start': TextEditingController(text: '101'), 'end': TextEditingController(text: '0'), 'price': TextEditingController(text: '3000')},
                                ];
                              }
                            });
                          }),
                          const SizedBox(width: 8),
                          _suggestionChip('Điện (Giá cố định)', () {
                            setSheetState(() {
                              nameCtrl.text = 'Điện';
                              chargeType = 'METERED';
                              unitCtrl.text = 'kWh';
                              priceCtrl.text = '3500';
                              mandatory = true;
                            });
                          }),
                          const SizedBox(width: 8),
                          _suggestionChip('Nước (Theo chỉ số)', () {
                            setSheetState(() {
                              nameCtrl.text = 'Nước sinh hoạt';
                              chargeType = 'METERED';
                              unitCtrl.text = 'm³';
                              priceCtrl.text = '20000';
                              mandatory = true;
                            });
                          }),
                          const SizedBox(width: 8),
                          _suggestionChip('Nước (Theo người)', () {
                            setSheetState(() {
                              nameCtrl.text = 'Nước sinh hoạt';
                              chargeType = 'PER_PERSON';
                              unitCtrl.text = 'người/tháng';
                              priceCtrl.text = '100000';
                              mandatory = true;
                            });
                          }),
                          const SizedBox(width: 8),
                          _suggestionChip('Internet / Wifi', () {
                            setSheetState(() {
                              nameCtrl.text = 'Internet / Wifi';
                              chargeType = 'FIXED';
                              unitCtrl.text = 'tháng';
                              priceCtrl.text = '100000';
                              mandatory = false;
                            });
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    _buildField('Tên dịch vụ *', nameCtrl, 'VD: Điện, Nước, Rác...'),
                    const SizedBox(height: 14),

                    const Text('Loại tính phí *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: chargeType,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'FIXED', child: Text('Cố định (hàng tháng)')),
                        DropdownMenuItem(value: 'PER_PERSON', child: Text('Theo người')),
                        DropdownMenuItem(value: 'PER_QUANTITY', child: Text('Theo số lượng')),
                        DropdownMenuItem(value: 'PER_INDEX', child: Text('Điện nước theo chỉ số BẬC THANG')),
                        DropdownMenuItem(value: 'METERED', child: Text('Điện nước theo chỉ số CỐ ĐỊNH')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() {
                            chargeType = val;
                            if (val == 'PER_INDEX' && tierCtrls.isEmpty) {
                              tierCtrls = [
                                {'start': TextEditingController(text: '0'), 'end': TextEditingController(text: '50'), 'price': TextEditingController(text: '2000')},
                                {'start': TextEditingController(text: '51'), 'end': TextEditingController(text: '100'), 'price': TextEditingController(text: '2500')},
                                {'start': TextEditingController(text: '101'), 'end': TextEditingController(text: '0'), 'price': TextEditingController(text: '3000')},
                              ];
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    _buildField('Đơn vị tính', unitCtrl, 'kWh, m³, tháng, người...'),
                    const SizedBox(height: 14),

                    if (!isTiered) ...[
                      _buildField(
                        chargeType == 'FIXED' ? 'Phí cố định (đ/tháng) *' : 'Đơn giá cơ bản (đ/đơn vị) *',
                        priceCtrl,
                        '0',
                        inputType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                    ] else ...[
                      // Tiered price configuration
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Cấu hình bậc giá lũy tiến (Điện/Nước)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                GestureDetector(
                                  onTap: () {
                                    setSheetState(() {
                                      final lastEnd = tierCtrls.isNotEmpty ? (int.tryParse(tierCtrls.last['end']!.text) ?? 0) : 0;
                                      tierCtrls.add({
                                        'start': TextEditingController(text: '${lastEnd + 1}'),
                                        'end': TextEditingController(text: '0'),
                                        'price': TextEditingController(text: '3000'),
                                      });
                                    });
                                  },
                                  child: const Text('+ Thêm bậc', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...tierCtrls.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final ctrls = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller: ctrls['start'],
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(fontSize: 13),
                                        decoration: const InputDecoration(labelText: 'Từ', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8)),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller: ctrls['end'],
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(fontSize: 13),
                                        decoration: const InputDecoration(labelText: 'Đến (0: max)', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8)),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      flex: 3,
                                      child: TextField(
                                        controller: ctrls['price'],
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(fontSize: 13),
                                        decoration: const InputDecoration(labelText: 'Đơn giá', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8)),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger, size: 20),
                                      onPressed: () {
                                        setSheetState(() => tierCtrls.removeAt(idx));
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    SwitchListTile(
                      value: mandatory,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Dịch vụ bắt buộc', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Tự động áp dụng cho tất cả hợp đồng mới', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                      onChanged: (val) => setSheetState(() => mandatory = val),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
                            ),
                            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (nameCtrl.text.trim().isEmpty) return;
                              Navigator.pop(ctx);

                              final tiers = isTiered
                                  ? tierCtrls.map((c) => {
                                        'tierStart': double.tryParse(c['start']!.text) ?? 0,
                                        'tierEnd': double.tryParse(c['end']!.text) ?? 0,
                                        'pricePerUnit': double.tryParse(c['price']!.text) ?? 0,
                                      }).toList()
                                  : null;

                              final payload = {
                                'name': nameCtrl.text.trim(),
                                'chargeType': chargeType,
                                'unit': unitCtrl.text.trim(),
                                'mandatory': mandatory,
                                'basePrice': isTiered ? 0 : (double.tryParse(priceCtrl.text) ?? 0),
                                if (tiers != null) 'pricingTiers': tiers,
                              };

                              try {
                                if (editing != null) {
                                  await ServiceService.update(_selectedMotel!.id, editing.id, payload);
                                } else {
                                  await ServiceService.create(_selectedMotel!.id, payload);
                                }
                                _loadServicesForMotel(_selectedMotel!);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(editing != null ? 'Đã cập nhật dịch vụ!' : 'Đã thêm dịch vụ thành công!'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(editing != null ? 'Lưu thay đổi' : 'Thêm Dịch Vụ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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

  Widget _suggestionChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, {TextInputType inputType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: inputType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }
}
