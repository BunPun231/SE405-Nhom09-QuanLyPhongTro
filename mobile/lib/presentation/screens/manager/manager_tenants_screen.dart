import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/resident_service.dart';

class ManagerTenantsScreen extends StatefulWidget {
  const ManagerTenantsScreen({Key? key}) : super(key: key);

  @override
  State<ManagerTenantsScreen> createState() => _ManagerTenantsScreenState();
}

class _ManagerTenantsScreenState extends State<ManagerTenantsScreen> {
  String _searchQuery = '';
  List<ResidentResult> _residents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResidents();
  }

  Future<void> _loadResidents() async {
    setState(() => _isLoading = true);
    try {
      final res = await ResidentService.list();
      if (mounted) {
        setState(() {
          _residents = res.content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _residents.where((r) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return r.fullName.toLowerCase().contains(q) ||
          r.phone.toLowerCase().contains(q) ||
          (r.idCardNumber != null && r.idCardNumber!.toLowerCase().contains(q));
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTenantSheet,
        backgroundColor: AppColors.primary,
        elevation: 2,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên, SĐT hoặc CCCD...',
                hintStyle: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondaryLight),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
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
                                width: 70, height: 70,
                                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
                                child: const Icon(Icons.people_outline_rounded, size: 36, color: AppColors.primary),
                              ),
                              const SizedBox(height: 16),
                              const Text('Chưa có khách thuê nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              const SizedBox(height: 6),
                              const Text('Nhấn nút + bên dưới để thêm khách thuê mới', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => _buildTenantCard(filtered[index]),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantCard(ResidentResult t) {
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
                    t.active ? 'Đang ở' : 'Đã rời',
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
                    const Icon(Icons.badge_outlined, size: 14, color: AppColors.textSecondaryLight),
                    const SizedBox(width: 4),
                    Text('CCCD: ${t.idCardNumber ?? 'Chưa cập nhật'}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                  ],
                ),
                if (t.email != null && t.email!.isNotEmpty)
                  Text(t.email!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTenantSheet() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final idCardCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

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
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Icon(Icons.person_add_rounded, color: AppColors.primary, size: 24),
                  SizedBox(width: 10),
                  Text('Thêm Khách Thuê Mới', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ],
              ),
              const SizedBox(height: 20),

              _buildField('Họ và tên *', nameCtrl, 'Nguyễn Văn A', Icons.person_outline),
              const SizedBox(height: 16),
              _buildField('Số điện thoại *', phoneCtrl, '0901234567', Icons.phone_outlined, inputType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildField('Số CCCD/CMND *', idCardCtrl, '079090000000', Icons.badge_outlined, inputType: TextInputType.number),
              const SizedBox(height: 16),
              _buildField('Email (không bắt buộc)', emailCtrl, 'email@example.com', Icons.email_outlined, inputType: TextInputType.emailAddress),
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
                            const SnackBar(content: Text('Vui lòng điền đủ họ tên, SĐT và CCCD!')),
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        try {
                          await ResidentService.create(
                            fullName: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            idCardNumber: idCardCtrl.text.trim(),
                            email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                          );
                          _loadResidents();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Đã thêm khách thuê thành công!'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      child: const Text('Lưu thông tin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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

  Widget _buildField(String label, TextEditingController ctrl, String hint, IconData icon, {TextInputType inputType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        TextField(
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
        ),
      ],
    );
  }
}
