import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/motel_service.dart';

class ManagerMotelsScreen extends StatefulWidget {
  const ManagerMotelsScreen({Key? key}) : super(key: key);

  @override
  State<ManagerMotelsScreen> createState() => _ManagerMotelsScreenState();
}

class _ManagerMotelsScreenState extends State<ManagerMotelsScreen> {
  List<MotelResult> _motels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMotels();
  }

  Future<void> _loadMotels() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final res = await MotelService.list();
      if (mounted) {
        setState(() {
          _motels = res.content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MODAL: Thêm mới hoặc Cập nhật khu trọ (tương ứng AddMotelModal của Web FE)
  // ─────────────────────────────────────────────────────────────────────────────
  void _showMotelFormSheet({MotelResult? existingMotel}) {
    final isEdit = existingMotel != null;
    final nameCtrl = TextEditingController(text: existingMotel?.name ?? '');
    final addressCtrl = TextEditingController(text: existingMotel?.address ?? '');
    final floorsCtrl = TextEditingController(text: (existingMotel?.totalFloors ?? 3).toString());
    final descCtrl = TextEditingController(text: existingMotel?.description ?? '');
    final billingDayCtrl = TextEditingController(text: (existingMotel?.billingCycleDay ?? 5).toString());
    final depositPercentCtrl = TextEditingController(text: (existingMotel?.depositPercent ?? 100).toStringAsFixed(0));

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isEdit ? Icons.edit_note_rounded : Icons.apartment_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Cập nhật khu trọ' : 'Thêm khu trọ mới',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                        ),
                        Text(
                          isEdit ? 'Chỉnh sửa thông tin tòa nhà' : 'Điền thông tin để tạo tòa nhà / dãy trọ mới',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildLabel('Tên khu trọ *'),
                const SizedBox(height: 6),
                _buildTextField(nameCtrl, 'Ví dụ: Tòa A, Nhà Trọ Hạnh Phúc...', Icons.apartment_rounded),
                const SizedBox(height: 16),

                _buildLabel('Địa chỉ *'),
                const SizedBox(height: 6),
                _buildTextField(addressCtrl, 'Số nhà, tên đường, phường/xã...', Icons.location_on_outlined),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Tổng số tầng *'),
                          const SizedBox(height: 6),
                          _buildTextField(floorsCtrl, '3', Icons.layers_rounded, inputType: TextInputType.number),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Ngày chốt tiền (1-31)'),
                          const SizedBox(height: 6),
                          _buildTextField(billingDayCtrl, '5', Icons.calendar_month_outlined, inputType: TextInputType.number),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildLabel('Tỷ lệ cọc mặc định (% giá phòng)'),
                const SizedBox(height: 6),
                _buildTextField(depositPercentCtrl, '100', Icons.percent_rounded, inputType: TextInputType.number),
                const SizedBox(height: 16),

                _buildLabel('Mô tả / Tiện ích chung'),
                const SizedBox(height: 6),
                _buildTextField(descCtrl, 'Giờ giấc tự do, khóa vân tay, camera an ninh...', Icons.description_outlined),
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
                          if (nameCtrl.text.trim().isEmpty || addressCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vui lòng điền đủ Tên và Địa chỉ!'), backgroundColor: AppColors.warning),
                            );
                            return;
                          }
                          Navigator.pop(ctx);
                          try {
                            final totalFloors = int.tryParse(floorsCtrl.text) ?? 1;
                            final billingDay = int.tryParse(billingDayCtrl.text);
                            final depositPercent = double.tryParse(depositPercentCtrl.text);

                            if (isEdit) {
                              await MotelService.update(existingMotel.id, {
                                'name': nameCtrl.text.trim(),
                                'address': addressCtrl.text.trim(),
                                'totalFloors': totalFloors,
                                if (billingDay != null) 'billingCycleDay': billingDay,
                                if (depositPercent != null) 'depositPercent': depositPercent,
                                'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                              });
                            } else {
                              await MotelService.create(
                                name: nameCtrl.text.trim(),
                                address: addressCtrl.text.trim(),
                                totalFloors: totalFloors,
                                billingCycleDay: billingDay,
                                depositPercent: depositPercent,
                                description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                              );
                            }

                            _loadMotels();

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isEdit ? 'Đã cập nhật thông tin khu trọ!' : 'Đã tạo khu trọ mới thành công!'),
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
                        child: Text(
                          isEdit ? 'Lưu thay đổi' : 'Tạo mới',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
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

  // ─────────────────────────────────────────────────────────────────────────────
  // Xóa khu trọ (tương ứng handleDeleteMotel của Web FE)
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> _deleteMotel(MotelResult motel) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận xóa khu trọ?'),
        content: Text(
          'Bạn có chắc chắn muốn xóa "${motel.name}" không?\n\nToàn bộ phòng và dữ liệu hợp đồng liên quan sẽ bị xóa.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await MotelService.delete(motel.id);
        _loadMotels();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xóa khu trọ "${motel.name}" thành công'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi xóa: $e'), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)));
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {TextInputType inputType = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: inputType,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _loadMotels,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
            : _motels.isEmpty
                ? _buildEmptyState()
                : _buildMotelList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMotelFormSheet(),
        backgroundColor: AppColors.primary,
        elevation: 2,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
        label: const Text('Thêm khu trọ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.apartment_rounded, size: 38, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text('Chưa có khu trọ nào', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 8),
            const Text(
              'Nhấn nút bên dưới để thêm\nkhu trọ đầu tiên của bạn',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight, height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => _showMotelFormSheet(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Thêm khu trọ', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotelList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _motels.length,
      itemBuilder: (context, index) {
        final m = _motels[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondaryLight),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  m.address,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Quick Action Menu (Sửa / Xóa)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondaryLight, size: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      onSelected: (val) {
                        if (val == 'edit') {
                          _showMotelFormSheet(existingMotel: m);
                        } else if (val == 'delete') {
                          _deleteMotel(m);
                        }
                      },
                      itemBuilder: (pCtx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                              SizedBox(width: 10),
                              Text('Chỉnh sửa', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                              SizedBox(width: 10),
                              Text('Xóa khu trọ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.danger)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Info Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildMetaChip(Icons.layers_rounded, '${m.totalFloors} tầng', const Color(0xFF0284C7)),
                    _buildMetaChip(Icons.calendar_today_rounded, 'Chốt ngày ${m.billingCycleDay ?? 5}', const Color(0xFFD97706)),
                    if (m.depositPercent != null)
                      _buildMetaChip(Icons.savings_outlined, 'Cọc ${m.depositPercent!.toStringAsFixed(0)}%', const Color(0xFF7C3AED)),
                  ],
                ),

                if (m.description != null && m.description!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    m.description!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],


              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetaChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
