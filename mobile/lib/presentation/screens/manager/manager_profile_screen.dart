import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';

class ManagerProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  const ManagerProfileScreen({Key? key, this.onLogout}) : super(key: key);

  @override
  State<ManagerProfileScreen> createState() => _ManagerProfileScreenState();
}

class _ManagerProfileScreenState extends State<ManagerProfileScreen> {
  String _fullName = '';
  String _role = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _fullName = prefs.getString('user_fullname') ?? 'Người dùng';
        _role = prefs.getString('user_role') ?? '';
      });
    }
  }

  String get _roleLabel {
    switch (_role.toUpperCase()) {
      case 'MANAGER': case 'OWNER': return 'Chủ trọ / Quản lý';
      case 'ADMIN': return 'Quản trị viên';
      case 'TENANT': return 'Khách thuê';
      case 'TECHNICIAN': return 'Kỹ thuật viên';
      default: return 'Người dùng';
    }
  }

  String get _avatarLetter {
    final parts = _fullName.trim().split(' ');
    return parts.isNotEmpty && parts.last.isNotEmpty ? parts.last[0].toUpperCase() : 'U';
  }

  void _showChangePasswordSheet() {
    final oldPwdCtrl = TextEditingController();
    final newPwdCtrl = TextEditingController();
    final confirmPwdCtrl = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;
    String? errorMsg;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
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
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Đổi mật khẩu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                        Text('Bảo mật tài khoản của bạn', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (errorMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(errorMsg!, style: const TextStyle(fontSize: 12, color: AppColors.danger))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                _buildPasswordField(
                  label: 'Mật khẩu hiện tại',
                  ctrl: oldPwdCtrl,
                  obscure: obscureOld,
                  onToggle: () => setSheetState(() => obscureOld = !obscureOld),
                ),
                const SizedBox(height: 16),
                _buildPasswordField(
                  label: 'Mật khẩu mới',
                  ctrl: newPwdCtrl,
                  obscure: obscureNew,
                  onToggle: () => setSheetState(() => obscureNew = !obscureNew),
                ),
                const SizedBox(height: 16),
                _buildPasswordField(
                  label: 'Xác nhận mật khẩu mới',
                  ctrl: confirmPwdCtrl,
                  obscure: obscureConfirm,
                  onToggle: () => setSheetState(() => obscureConfirm = !obscureConfirm),
                ),
                const SizedBox(height: 28),
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
                        onPressed: isLoading ? null : () async {
                          if (oldPwdCtrl.text.isEmpty || newPwdCtrl.text.isEmpty || confirmPwdCtrl.text.isEmpty) {
                            setSheetState(() => errorMsg = 'Vui lòng điền đầy đủ thông tin');
                            return;
                          }
                          if (newPwdCtrl.text != confirmPwdCtrl.text) {
                            setSheetState(() => errorMsg = 'Mật khẩu mới không khớp');
                            return;
                          }
                          if (newPwdCtrl.text.length < 6) {
                            setSheetState(() => errorMsg = 'Mật khẩu mới phải từ 6 ký tự');
                            return;
                          }
                          setSheetState(() { isLoading = true; errorMsg = null; });
                          try {
                            await AuthService.changePassword(
                              oldPassword: oldPwdCtrl.text,
                              newPassword: newPwdCtrl.text,
                              confirmPassword: confirmPwdCtrl.text,
                            );
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: const Text('Đổi mật khẩu thành công!'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ));
                            }
                          } catch (e) {
                            setSheetState(() {
                              isLoading = false;
                              errorMsg = e.toString().replaceAll('Exception: ', '');
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Xác nhận', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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

  Widget _buildPasswordField({required String label, required TextEditingController ctrl, required bool obscure, required VoidCallback onToggle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textSecondaryLight),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: AppColors.textSecondaryLight),
              onPressed: onToggle,
            ),
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

  void _confirmLogout() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('Đăng xuất?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Bạn có chắc muốn đăng xuất khỏi tài khoản?', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
            const SizedBox(height: 28),
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
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await AuthService.logout();
                      widget.onLogout?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Đăng xuất', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                    alignment: Alignment.center,
                    child: Text(_avatarLetter, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 22)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_fullName.isEmpty ? '...' : _fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                          child: Text(_roleLabel, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bảo mật
            _buildGroup(
              title: 'Bảo mật',
              children: [
                _buildTile(
                  icon: Icons.lock_outline_rounded,
                  color: AppColors.primary,
                  title: 'Đổi mật khẩu',
                  subtitle: 'Cập nhật mật khẩu đăng nhập',
                  onTap: _showChangePasswordSheet,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Thanh toán
            _buildGroup(
              title: 'Thanh toán & Ngân hàng',
              children: [
                _buildTile(
                  icon: Icons.qr_code_scanner_rounded,
                  color: const Color(0xFF0EA5E9),
                  title: 'Cấu hình VietQR',
                  subtitle: 'Kết nối ngân hàng để tự đối soát',
                  onTap: () {},
                ),
                _buildTile(
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppColors.success,
                  title: 'Ví & Cổng thanh toán',
                  subtitle: 'MoMo, VNPay, ZaloPay',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Thông báo
            _buildGroup(
              title: 'Thông báo',
              children: [
                _buildTile(
                  icon: Icons.notifications_none_rounded,
                  color: const Color(0xFF8B5CF6),
                  title: 'Cài đặt thông báo',
                  subtitle: 'Nhắc nợ, cảnh báo, thông báo hệ thống',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Logout
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.danger, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 18),
                label: const Text('Đăng xuất', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: _confirmLogout,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroup({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF374151))),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
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
                width: 40, height: 40,
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
