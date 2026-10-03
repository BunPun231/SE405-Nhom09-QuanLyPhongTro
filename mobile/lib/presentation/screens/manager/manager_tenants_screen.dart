import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/resident_service.dart';
import '../../../core/services/invoice_service.dart';

class ManagerTenantsScreen extends StatefulWidget {
  const ManagerTenantsScreen({Key? key}) : super(key: key);

  @override
  State<ManagerTenantsScreen> createState() => _ManagerTenantsScreenState();
}

class _ManagerTenantsScreenState extends State<ManagerTenantsScreen> {
  String _searchQuery = '';
  String _statusFilter = 'ALL'; // ALL | ACTIVE | INACTIVE
  List<ResidentResult> _residents = [];
  Map<String, double> _balances = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResidents();
  }

  Future<void> _loadResidents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final res = await ResidentService.list(size: 100);
      if (!mounted) return;
      setState(() {
        _residents = res.content;
      });

      // Lấy số dư tài khoản của các cư dân (tương ứng web frontend)
      if (_residents.isNotEmpty) {
        final ids = _residents.map((r) => r.userId).toList();
        try {
          final balanceMap = await InvoiceService.getResidentBalances(ids);
          if (mounted) {
            setState(() {
              _balances = balanceMap;
            });
          }
        } catch (e) {
          debugPrint('Failed to load resident balances: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading residents: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MODAL: Xem chi tiết khách thuê (tương ứng Resident Detail Modal của Web FE)
  // ─────────────────────────────────────────────────────────────────────────────
  void _showResidentDetailSheet(ResidentResult resident) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (detailCtx, setDetailState) {
          final balance = _balances[resident.userId] ?? 0.0;
          final balanceFormatted = balance.toStringAsFixed(0).replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (m) => '${m[1]}.',
              );

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(detailCtx).viewInsets.bottom),
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

                    // Header: Avatar + Tên + Badge trạng thái
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            resident.fullName.isNotEmpty ? resident.fullName.substring(0, 1).toUpperCase() : 'K',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resident.fullName,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: resident.active ? AppColors.success : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    resident.active ? 'Đang hoạt động' : 'Không hoạt động',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: resident.active ? AppColors.success : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(detailCtx);
                            _showResidentFormSheet(editingResident: resident);
                          },
                          icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 22),
                          tooltip: 'Chỉnh sửa',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Khối hiển thị số dư tài khoản (như Web FE: resident-balance-box)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFDCFCE7)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.success, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Số dư tài khoản', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                                Text('Tự động khấu trừ vào hóa đơn kế tiếp', style: TextStyle(fontSize: 10, color: Color(0xFF15803D))),
                              ],
                            ),
                          ),
                          Text(
                            '$balanceFormatted đ',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Thông tin liên hệ & CCCD
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(Icons.phone_outlined, 'Số điện thoại', resident.phone),
                          const Divider(height: 20, color: Color(0xFFE2E8F0)),
                          _buildDetailRow(Icons.email_outlined, 'Email', resident.email ?? '—'),
                          const Divider(height: 20, color: Color(0xFFE2E8F0)),
                          _buildDetailRow(Icons.badge_outlined, 'Số CCCD/CMND', resident.idCardNumber ?? '—'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Hiển thị ảnh CCCD minh chứng (nếu có)
                    if (resident.idCardFrontUrl != null || resident.idCardBackUrl != null) ...[
                      const Text('Ảnh CCCD minh chứng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Mặt trước', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                                const SizedBox(height: 6),
                                _buildCccdImage(resident.idCardFrontUrl),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Mặt sau', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                                const SizedBox(height: 6),
                                _buildCccdImage(resident.idCardBackUrl),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Nút thao tác: Vô hiệu hóa (Deactivate) / Sửa / Đóng
                    Row(
                      children: [
                        if (resident.active) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: detailCtx,
                                  builder: (dCtx) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    title: const Text('Xác nhận vô hiệu hóa?'),
                                    content: Text('Bạn có chắc chắn muốn vô hiệu hóa khách thuê "${resident.fullName}"?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Hủy')),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(dCtx, true),
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                                        child: const Text('Vô hiệu hóa', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  try {
                                    await ResidentService.deactivate(resident.userId);
                                    if (!detailCtx.mounted) return;
                                    Navigator.pop(detailCtx);
                                    _loadResidents();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Đã vô hiệu hóa khách thuê "${resident.fullName}"'),
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
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger,
                                side: const BorderSide(color: Color(0xFFFCA5A5)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('Vô hiệu hóa', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(detailCtx);
                              _showResidentFormSheet(editingResident: resident);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Chỉnh sửa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  // ─────────────────────────────────────────────────────────────────────────────
  // MODAL: Thêm mới hoặc Cập nhật khách thuê (AddResidentModal trên Web FE)
  // ─────────────────────────────────────────────────────────────────────────────
  void _showResidentFormSheet({ResidentResult? editingResident}) {
    final isEditing = editingResident != null;
    final nameCtrl = TextEditingController(text: editingResident?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: editingResident?.phone ?? '');
    final idCardCtrl = TextEditingController(text: editingResident?.idCardNumber ?? '');
    final emailCtrl = TextEditingController(text: editingResident?.email ?? '');

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
                    decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
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
                        isEditing ? Icons.person_outline : Icons.person_add_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Cập nhật khách thuê' : 'Thêm khách thuê mới',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                        ),
                        Text(
                          isEditing ? 'Chỉnh sửa thông tin hồ sơ' : 'Tạo hồ sơ và tài khoản khách thuê',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildField('Họ và tên *', nameCtrl, 'Nguyễn Văn A', Icons.person_outline),
                const SizedBox(height: 16),

                _buildField(
                  'Số điện thoại *',
                  phoneCtrl,
                  '0901234567',
                  Icons.phone_outlined,
                  inputType: TextInputType.phone,
                  enabled: !isEditing, // Không đổi SĐT khi sửa theo quy tắc Web FE
                ),
                const SizedBox(height: 16),

                _buildField('Số CCCD/CMND *', idCardCtrl, '079090000000', Icons.badge_outlined, inputType: TextInputType.number),
                const SizedBox(height: 16),

                _buildField('Email (không bắt buộc)', emailCtrl, 'email@example.com', Icons.email_outlined, inputType: TextInputType.emailAddress),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textSecondaryLight),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mật khẩu mặc định sẽ là số điện thoại. Khách thuê cần đổi mật khẩu khi đăng nhập lần đầu.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight, height: 1.4),
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
                          if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty || idCardCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vui lòng điền đủ họ tên, SĐT và CCCD!'), backgroundColor: AppColors.warning),
                            );
                            return;
                          }
                          Navigator.pop(ctx);
                          try {
                            if (isEditing) {
                              await ResidentService.update(editingResident.userId, {
                                'fullName': nameCtrl.text.trim(),
                                'idCardNumber': idCardCtrl.text.trim(),
                                'email': emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                              });
                            } else {
                              await ResidentService.create(
                                fullName: nameCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                                idCardNumber: idCardCtrl.text.trim(),
                                email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                              );
                            }
                            _loadResidents();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isEditing ? 'Đã cập nhật khách thuê thành công!' : 'Đã thêm khách thuê thành công!'),
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
                          isEditing ? 'Lưu thay đổi' : 'Thêm khách thuê',
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

  Widget _buildCccdImage(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        height: 90,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text('Chưa có ảnh', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
        ),
      );
    }

    if (url.startsWith('data:image')) {
      try {
        final commaIdx = url.indexOf(',');
        final base64Str = url.substring(commaIdx + 1);
        final bytes = base64Decode(base64Str);
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(bytes, height: 90, width: double.infinity, fit: BoxFit.cover),
        );
      } catch (e) {
        // Fallback
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        height: 90,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (ctx, _, __) => Container(
          height: 90,
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
          child: const Center(child: Icon(Icons.broken_image_rounded, color: AppColors.textSecondaryLight)),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondaryLight),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
        ),
      ],
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType inputType = TextInputType.text,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          enabled: enabled,
          keyboardType: inputType,
          style: TextStyle(fontSize: 14, color: enabled ? const Color(0xFF1E293B) : const Color(0xFF64748B)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
            prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondaryLight),
            filled: true,
            fillColor: enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _residents.where((r) {
      if (_statusFilter == 'ACTIVE' && !r.active) return false;
      if (_statusFilter == 'INACTIVE' && r.active) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return r.fullName.toLowerCase().contains(q) ||
          r.phone.toLowerCase().contains(q) ||
          (r.idCardNumber != null && r.idCardNumber!.toLowerCase().contains(q)) ||
          (r.email != null && r.email!.toLowerCase().contains(q));
    }).toList();

    final activeCount = _residents.where((r) => r.active).length;
    final inactiveCount = _residents.where((r) => !r.active).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showResidentFormSheet(),
        backgroundColor: AppColors.primary,
        elevation: 2,
        tooltip: 'Thêm khách mới',
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      body: Column(
        children: [
          // Thống kê nhanh 2 card (Đang hoạt động & Không hoạt động như Web FE)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.person_outline_rounded, color: AppColors.success, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Đang hoạt động', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                            Text('$activeCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF64748B).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.person_off_outlined, color: Color(0xFF64748B), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Không h/động', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                            Text('$inactiveCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar & Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên, SĐT, CCCD...',
                hintStyle: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondaryLight, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
            ),
          ),

          // Filter bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Row(
              children: [
                _filterChip('Tất cả (${_residents.length})', 'ALL'),
                _filterChip('Đang hoạt động ($activeCount)', 'ACTIVE'),
                _filterChip('Không hoạt động ($inactiveCount)', 'INACTIVE'),
              ],
            ),
          ),

          // List of Tenants
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadResidents,
              color: AppColors.primary,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
                                child: const Icon(Icons.people_outline_rounded, size: 36, color: AppColors.primary),
                              ),
                              const SizedBox(height: 16),
                              const Text('Không tìm thấy khách thuê', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              const SizedBox(height: 6),
                              const Text('Thử thay đổi bộ lọc hoặc thêm khách thuê mới', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 90),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => _buildTenantCard(filtered[index]),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _statusFilter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
                const Icon(Icons.check_rounded, size: 12, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTenantCard(ResidentResult t) {
    final balance = _balances[t.userId] ?? 0.0;
    final balanceFormatted = balance.toStringAsFixed(0).replaceAllMapped(
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showResidentDetailSheet(t),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        t.fullName.isNotEmpty ? t.fullName.substring(0, 1).toUpperCase() : 'K',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                          const SizedBox(height: 3),
                          Text('SĐT: ${t.phone}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: t.active ? AppColors.success.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        t.active ? 'Hoạt động' : 'Không h/đ',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: t.active ? AppColors.success : Colors.grey),
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
                        const Icon(Icons.account_balance_wallet_outlined, size: 13, color: AppColors.textSecondaryLight),
                        const SizedBox(width: 4),
                        Text(
                          'Số dư: $balanceFormatted đ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: balance > 0 ? AppColors.success : const Color(0xFF1E293B),
                          ),
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
