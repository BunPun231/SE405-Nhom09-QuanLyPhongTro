import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/session/user_session.dart';
import '../../widgets/account_widgets.dart';

class TechnicianProfileScreen extends StatelessWidget {
  final VoidCallback? onLogout;

  const TechnicianProfileScreen({Key? key, this.onLogout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        ValueListenableBuilder<String?>(
          valueListenable: UserSession.displayName,
          builder: (context, name, _) => ProfileSummaryCard(name: name ?? 'Kỹ thuật viên', badge: 'Kỹ thuật viên'),
        ),
        const SizedBox(height: 20),
        const ProfileSectionTitle('Tài khoản & Bảo mật'),
        ProfileMenuCard(tiles: [
          ProfileTile(
            icon: Icons.person_outline_rounded,
            color: const Color(0xFF10B981),
            title: 'Thông tin cá nhân',
            subtitle: 'Họ tên, số điện thoại, email',
            onTap: () => showProfileSheet(context),
          ),
          ProfileTile(
            icon: Icons.lock_reset_rounded,
            color: const Color(0xFF3B82F6),
            title: 'Đổi mật khẩu',
            subtitle: 'Cập nhật mật khẩu bảo vệ tài khoản',
            onTap: () => showChangePasswordSheet(context),
          ),
        ]),
        const SizedBox(height: 20),
        const ProfileSectionTitle('Phiên đăng nhập'),
        ProfileMenuCard(tiles: [
          ProfileTile(
            icon: Icons.logout_rounded,
            color: AppColors.danger,
            title: 'Đăng xuất',
            subtitle: 'Thoát tài khoản khỏi thiết bị này',
            onTap: () => confirmLogout(context, roleLabel: 'kỹ thuật viên', onConfirm: () => onLogout?.call()),
          ),
        ]),
      ],
    );
  }
}
