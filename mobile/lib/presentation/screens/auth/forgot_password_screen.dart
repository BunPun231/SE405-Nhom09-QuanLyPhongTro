import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';

/// UC06: Khôi phục mật khẩu — 3 bước giống web: (1) nhập SĐT/email, (2) nhập OTP, (3) mật khẩu mới.
class ForgotPasswordScreen extends StatefulWidget {
  final VoidCallback? onNavigateLogin;

  const ForgotPasswordScreen({Key? key, this.onNavigateLogin}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const int _resendSeconds = 60;

  final _identityController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPwdController = TextEditingController();
  final _confirmPwdController = TextEditingController();

  int _step = 1; // 1: identity, 2: otp, 3: mật khẩu mới, 4: thành công
  bool _loading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _error;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _identityController.dispose();
    _otpController.dispose();
    _newPwdController.dispose();
    _confirmPwdController.dispose();
    super.dispose();
  }

  String get _identity => _identityController.text.trim();

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _countdown--);
      if (_countdown <= 0) t.cancel();
    });
  }

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = _msg(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendOtp({bool resend = false}) async {
    if (_identity.isEmpty) {
      setState(() => _error = 'Vui lòng nhập số điện thoại hoặc email');
      return;
    }
    await _run(() async {
      await AuthService.forgotPassword(_identity);
      if (!mounted) return;
      _startCountdown();
      if (resend) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi lại mã OTP')));
      } else {
        setState(() => _step = 2);
      }
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Mã OTP gồm 6 chữ số');
      return;
    }
    await _run(() async {
      await AuthService.verifyOtp(identity: _identity, otp: otp);
      if (mounted) setState(() => _step = 3);
    });
  }

  Future<void> _resetPassword() async {
    final newPwd = _newPwdController.text;
    if (newPwd.length < 8) {
      setState(() => _error = 'Mật khẩu mới phải có ít nhất 8 ký tự');
      return;
    }
    if (newPwd != _confirmPwdController.text) {
      setState(() => _error = 'Xác nhận mật khẩu không khớp');
      return;
    }
    await _run(() async {
      await AuthService.resetPassword(
        identity: _identity,
        otp: _otpController.text.trim(),
        newPassword: newPwd,
        confirmPassword: _confirmPwdController.text,
      );
      if (mounted) setState(() => _step = 4);
    });
  }

  void _back() {
    if (_step == 2 || _step == 3) {
      setState(() {
        _step--;
        _error = null;
      });
    } else {
      (widget.onNavigateLogin ?? () => Navigator.pop(context))();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Khôi phục mật khẩu', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimaryLight),
          onPressed: _step == 4 ? null : _back,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(key: ValueKey(_step), child: _buildStep()),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 1:
        return _stepIdentity();
      case 2:
        return _stepOtp();
      case 3:
        return _stepNewPassword();
      default:
        return _stepDone();
    }
  }

  // ─── Các bước ──────────────────────────────────────────────────────────────

  Widget _stepIdentity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _progress(1),
        const SizedBox(height: 24),
        const Text('Quên mật khẩu?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Nhập số điện thoại hoặc email đã đăng ký để nhận mã OTP khôi phục mật khẩu.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
        const SizedBox(height: 24),
        TextField(
          controller: _identityController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _sendOtp(),
          decoration: InputDecoration(
            labelText: 'Số điện thoại hoặc email',
            prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textSecondaryLight),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        _errorBox(),
        const SizedBox(height: 24),
        _primaryButton('Gửi mã OTP', _sendOtp),
      ],
    );
  }

  Widget _stepOtp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _progress(2),
        const SizedBox(height: 24),
        const Text('Nhập mã xác thực', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
            children: [
              const TextSpan(text: 'Mã OTP gồm 6 chữ số đã được gửi tới '),
              TextSpan(text: _identity, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight)),
              const TextSpan(text: '. Mã có hiệu lực trong 5 phút.'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 10),
          onChanged: (_) => setState(() => _error = null),
          decoration: InputDecoration(
            counterText: '',
            hintText: '••••••',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        _errorBox(),
        const SizedBox(height: 16),
        _primaryButton('Xác nhận', _verifyOtp),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: _countdown > 0 || _loading ? null : () => _sendOtp(resend: true),
            child: Text(_countdown > 0 ? 'Gửi lại mã sau ${_countdown}s' : 'Gửi lại mã OTP'),
          ),
        ),
      ],
    );
  }

  Widget _stepNewPassword() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _progress(3),
        const SizedBox(height: 24),
        const Text('Đặt mật khẩu mới', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Mật khẩu mới cần có ít nhất 8 ký tự.', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
        const SizedBox(height: 24),
        TextField(
          controller: _newPwdController,
          obscureText: _obscureNew,
          decoration: InputDecoration(
            labelText: 'Mật khẩu mới',
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondaryLight),
            suffixIcon: IconButton(
              icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, size: 20),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmPwdController,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            labelText: 'Xác nhận mật khẩu mới',
            prefixIcon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.textSecondaryLight),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        _errorBox(),
        const SizedBox(height: 24),
        _primaryButton('Đặt lại mật khẩu', _resetPassword),
      ],
    );
  }

  Widget _stepDone() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, size: 48, color: AppColors.success),
          ),
          const SizedBox(height: 20),
          const Text('Đặt lại mật khẩu thành công', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Bạn có thể đăng nhập bằng mật khẩu mới.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
          const SizedBox(height: 32),
          _primaryButton('Quay lại đăng nhập', () async => (widget.onNavigateLogin ?? () => Navigator.pop(context))()),
        ],
      ),
    );
  }

  // ─── Thành phần dùng chung ────────────────────────────────────────────────

  Widget _progress(int current) {
    return Row(
      children: List.generate(3, (i) {
        final active = i < current;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _errorBox() {
    if (_error == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
    );
  }

  Widget _primaryButton(String label, Future<void> Function() onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _loading ? null : onPressed,
        child: _loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}
