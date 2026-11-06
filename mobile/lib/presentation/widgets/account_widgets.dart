import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_service.dart';

/// Widget dùng chung cho các màn "Tài khoản" (UC03 xem, UC04 sửa hồ sơ, UC05 đổi mật khẩu).

String _err(Object e) => e.toString().replaceFirst('Exception: ', '');

const _roleLabels = {
  'ADMIN': 'Quản trị viên',
  'MANAGER': 'Chủ trọ / Quản lý',
  'RESIDENT': 'Khách thuê',
  'TENANT': 'Khách thuê',
  'TECHNICIAN': 'Kỹ thuật viên',
};

const _statusLabels = {
  'ACTIVE': 'Đang hoạt động',
  'LOCKED': 'Đã khóa',
  'PENDING': 'Chờ kích hoạt',
  'INACTIVE': 'Ngưng hoạt động',
};

// ─── Khối giao diện ──────────────────────────────────────────────────────────

class ProfileSummaryCard extends StatelessWidget {
  final String name;
  final String badge;

  const ProfileSummaryCard({Key? key, required this.name, required this.badge}) : super(key: key);

  String get _letter {
    final parts = name.trim().split(' ');
    return parts.isNotEmpty && parts.last.isNotEmpty ? parts.last[0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary,
            child: Text(_letter, style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(badge, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class ProfileSectionTitle extends StatelessWidget {
  final String title;
  const ProfileSectionTitle(this.title, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF374151))),
    );
  }
}

/// Khối trắng bo góc chứa các [ProfileTile], tự chèn đường kẻ giữa các dòng.
class ProfileMenuCard extends StatelessWidget {
  final List<Widget> tiles;
  const ProfileMenuCard({Key? key, required this.tiles}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      if (i > 0) children.add(const Divider(height: 1, indent: 60));
      children.add(tiles[i]);
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(children: children),
    );
  }
}

class ProfileTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ProfileTile({
    Key? key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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

Future<void> confirmLogout(BuildContext context, {required String roleLabel, required VoidCallback onConfirm}) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Đăng xuất?', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản $roleLabel?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
          child: const Text('Đăng xuất'),
        ),
      ],
    ),
  );
}

// ─── Bottom sheet dùng chung ────────────────────────────────────────────────

Widget _sheetShell(BuildContext ctx, {required String title, String? subtitle, required Widget child}) {
  return Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
    child: Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    ),
  );
}

Widget _errorBanner(String? message) {
  if (message == null) return const SizedBox.shrink();
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
    child: Text(message, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
  );
}

Widget _submitButton({required String label, required bool loading, required VoidCallback? onPressed}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
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

// ─── UC05: Đổi mật khẩu ─────────────────────────────────────────────────────

Future<void> showChangePasswordSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _ChangePasswordSheet(),
  );
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final oldP = _oldCtrl.text;
    final newP = _newCtrl.text;
    final conf = _confirmCtrl.text;
    if (oldP.isEmpty || newP.isEmpty) {
      setState(() => _error = 'Vui lòng nhập đầy đủ thông tin');
      return;
    }
    if (newP.length < 8) {
      setState(() => _error = 'Mật khẩu mới phải có ít nhất 8 ký tự');
      return;
    }
    if (newP != conf) {
      setState(() => _error = 'Xác nhận mật khẩu không khớp');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.changePassword(oldPassword: oldP, newPassword: newP, confirmPassword: conf);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công!'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _err(e);
        });
      }
    }
  }

  Widget _field(TextEditingController c, String label, IconData icon, bool obscure, VoidCallback toggle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 20), onPressed: toggle),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _sheetShell(
      context,
      title: 'Đổi mật khẩu',
      subtitle: 'Mật khẩu mới tối thiểu 8 ký tự',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _errorBanner(_error),
          _field(_oldCtrl, 'Mật khẩu hiện tại', Icons.lock_outline_rounded, _obscureOld, () => setState(() => _obscureOld = !_obscureOld)),
          _field(_newCtrl, 'Mật khẩu mới', Icons.lock_reset_rounded, _obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
          _field(_confirmCtrl, 'Xác nhận mật khẩu mới', Icons.check_circle_outline_rounded, _obscureConfirm,
              () => setState(() => _obscureConfirm = !_obscureConfirm)),
          const SizedBox(height: 8),
          _submitButton(label: 'Lưu mật khẩu mới', loading: _loading, onPressed: _submit),
        ],
      ),
    );
  }
}

// ─── UC03/UC04: Xem & sửa hồ sơ cá nhân ─────────────────────────────────────

Future<void> showProfileSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _ProfileSheet(),
  );
}

class _ProfileSheet extends StatefulWidget {
  const _ProfileSheet();

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  UserProfile? _profile;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await UserService.getProfile();
      if (!mounted) return;
      _nameCtrl.text = p.fullName;
      _phoneCtrl.text = p.phone;
      _emailCtrl.text = p.email ?? '';
      setState(() {
        _profile = p;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _err(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Vui lòng nhập họ và tên');
      return;
    }
    if (phone.isNotEmpty && !RegExp(r'^[0-9]{10,11}$').hasMatch(phone)) {
      setState(() => _error = 'Số điện thoại phải gồm 10–11 chữ số');
      return;
    }
    if (email.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = 'Email không hợp lệ');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await UserService.updateProfile(fullName: name, phone: phone, email: email);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('Đã cập nhật hồ sơ'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = _err(e);
        });
      }
    }
  }

  Widget _field(TextEditingController c, String label, IconData icon, {TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final p = _profile;
    return _sheetShell(
      context,
      title: 'Thông tin cá nhân',
      subtitle: 'Cập nhật họ tên, số điện thoại và email của bạn',
      child: _loading
          ? const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()))
          : p == null
              ? Column(children: [
                  _errorBanner(_error),
                  Center(child: TextButton(onPressed: _load, child: const Text('Thử lại'))),
                ])
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _errorBanner(_error),
                    _field(_nameCtrl, 'Họ và tên', Icons.person_outline_rounded),
                    _field(_phoneCtrl, 'Số điện thoại', Icons.phone_outlined, type: TextInputType.phone),
                    _field(_emailCtrl, 'Email', Icons.mail_outline_rounded, type: TextInputType.emailAddress),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                      child: Column(children: [
                        _infoRow('Vai trò', _roleLabels[p.role] ?? p.role),
                        _infoRow('Trạng thái', _statusLabels[p.status] ?? p.status),
                        if (p.createdAt != null) _infoRow('Ngày tạo', fmt.format(p.createdAt!.toLocal())),
                        if (p.lastLoginAt != null) _infoRow('Đăng nhập gần nhất', fmt.format(p.lastLoginAt!.toLocal())),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    _submitButton(label: 'Lưu thay đổi', loading: _saving, onPressed: _save),
                  ],
                ),
    );
  }
}
