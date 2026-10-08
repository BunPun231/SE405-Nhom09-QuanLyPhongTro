import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/contract_service.dart';

class TenantProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const TenantProfileScreen({Key? key, this.onLogout}) : super(key: key);

  @override
  State<TenantProfileScreen> createState() => _TenantProfileScreenState();
}

class _TenantProfileScreenState extends State<TenantProfileScreen> {
  String _fullName = 'Khách thuê';
  String _roomInfo = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_fullname') ?? 'Khách thuê';

    String room = '';
    try {
      final contracts = await ContractService.listMine();
      if (contracts.isNotEmpty) {
        room = 'Phòng #${contracts.first.roomId}';
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _fullName = name;
        _roomInfo = room.isNotEmpty ? room : 'Khách thuê phòng';
      });
    }
  }

  String get _avatarLetter {
    final parts = _fullName.trim().split(' ');
    return parts.isNotEmpty && parts.last.isNotEmpty ? parts.last[0].toUpperCase() : 'T';
  }

  void _showChangePasswordSheet() {
    final oldPwdCtrl = TextEditingController();
    final newPwdCtrl = TextEditingController();
    final confirmPwdCtrl = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSubmitting = false;
    String? errorMsg;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                const Text('Đổi mật khẩu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                const Text('Mật khẩu mới tối thiểu 6 ký tự', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                const SizedBox(height: 16),
                if (errorMsg != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text(errorMsg!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                  ),
                TextField(
                  controller: oldPwdCtrl,
                  obscureText: obscureOld,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu hiện tại',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility, size: 20),
                      onPressed: () => setModalState(() => obscureOld = !obscureOld),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPwdCtrl,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới',
                    prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 20),
                      onPressed: () => setModalState(() => obscureNew = !obscureNew),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPwdCtrl,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu mới',
                    prefixIcon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
                      onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final oldP = oldPwdCtrl.text.trim();
                            final newP = newPwdCtrl.text.trim();
                            final conf = confirmPwdCtrl.text.trim();

                            if (oldP.isEmpty || newP.isEmpty) {
                              setModalState(() => errorMsg = 'Vui lòng nhập đầy đủ thông tin');
                              return;
                            }
                            if (newP.length < 6) {
                              setModalState(() => errorMsg = 'Mật khẩu mới phải từ 6 ký tự');
                              return;
                            }
                            if (newP != conf) {
                              setModalState(() => errorMsg = 'Xác nhận mật khẩu không khớp');
                              return;
                            }

                            setModalState(() {
                              isSubmitting = true;
                              errorMsg = null;
                            });

                            try {
                              await AuthService.changePassword(
                                oldPassword: oldP,
                                newPassword: newP,
                                confirmPassword: conf,
                              );
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đổi mật khẩu thành công!'), backgroundColor: AppColors.success),
                                );
                              }
                            } catch (e) {
                              setModalState(() {
                                isSubmitting = false;
                                errorMsg = e.toString().replaceFirst('Exception: ', '');
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Lưu mật khẩu mới', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đăng xuất?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản khách thuê?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onLogout?.call();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        // Avatar Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary,
                child: Text(
                  _avatarLetter,
                  style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _fullName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_roomInfo • Khách thuê',
                  style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Account settings section
        _buildSectionTitle('Tài khoản & Bảo mật'),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            children: [
              _buildTile(
                icon: Icons.lock_reset_rounded,
                color: const Color(0xFF3B82F6),
                title: 'Đổi mật khẩu',
                subtitle: 'Cập nhật mật khẩu bảo vệ tài khoản',
                onTap: _showChangePasswordSheet,
              ),
              const Divider(height: 1, indent: 60),
              _buildTile(
                icon: Icons.notifications_none_rounded,
                color: const Color(0xFF8B5CF6),
                title: 'Cài đặt thông báo',
                subtitle: 'Hóa đơn, nhắc hạn đóng tiền, bảo trì',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tính năng thông báo đang kích hoạt')),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Danger zone
        _buildSectionTitle('Phiên đăng nhập'),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: _buildTile(
            icon: Icons.logout_rounded,
            color: AppColors.danger,
            title: 'Đăng xuất',
            subtitle: 'Thoát tài khoản khỏi thiết bị này',
            onTap: _showLogoutDialog,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF374151)),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B))),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSecondaryLight),
            ],
          ),
        ),
      ),
    );
  }
}
