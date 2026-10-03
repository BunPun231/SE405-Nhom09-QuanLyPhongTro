import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/app_models.dart';
import '../../../core/services/auth_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final void Function(UserRole role, String userName)? onLoginSuccess;
  final VoidCallback? onNavigateRegister;
  final VoidCallback? onNavigateForgotPassword;

  const LoginScreen({
    Key? key,
    this.onLoginSuccess,
    this.onNavigateRegister,
    this.onNavigateForgotPassword,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  static UserRole _parseRole(String role) {
    switch (role.toUpperCase()) {
      case 'MANAGER':
      case 'OWNER':
        return UserRole.manager;
      case 'TENANT':
        return UserRole.tenant;
      case 'TECHNICIAN':
      case 'STAFF':
        return UserRole.technician;
      case 'ADMIN':
        return UserRole.admin;
      default:
        return UserRole.tenant;
    }
  }

  Future<void> _handleLogin() async {
    final identity = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (identity.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập đầy đủ số điện thoại và mật khẩu.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRes = await AuthService.login(identity, password);

      // Lưu role & tên người dùng vào SharedPreferences để giữ session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', authRes.role);
      await prefs.setString('user_fullname', authRes.fullName);

      final role = _parseRole(authRes.role);

      if (mounted && widget.onLoginSuccess != null) {
        widget.onLoginSuccess!(role, authRes.fullName);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Logo
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 1.5),
                  ),
                  child: const Icon(Icons.home_work_rounded, color: AppColors.primary, size: 38),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text('Smart Room Rental', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight, letterSpacing: -0.5)),
              ),
              const Center(
                child: Text('Quản lý phòng trọ thông minh', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
              ),
              const SizedBox(height: 44),
              const Text('Đăng nhập', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              const Text('Nhập thông tin tài khoản của bạn để tiếp tục', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
              const SizedBox(height: 28),

              // Phone Field
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại / Email',
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textSecondaryLight, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onSubmitted: (_) => _handleLogin(),
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondaryLight, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSecondaryLight, size: 20),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onNavigateForgotPassword ?? () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
                  },
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  child: const Text('Quên mật khẩu?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),

              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: AppColors.danger))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Đăng nhập', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.2)),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chưa có tài khoản? ', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
                  GestureDetector(
                    onTap: widget.onNavigateRegister ?? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RegisterScreen(
                            onNavigateLogin: () => Navigator.pop(context),
                          ),
                        ),
                      );
                    },
                    child: const Text('Đăng ký ngay', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
