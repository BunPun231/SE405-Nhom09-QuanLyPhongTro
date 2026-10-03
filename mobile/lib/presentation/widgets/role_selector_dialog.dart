import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/app_models.dart';

class RoleSelectorDialog extends StatelessWidget {
  final UserRole currentRole;
  final ValueChanged<UserRole> onRoleSelected;

  const RoleSelectorDialog({
    Key? key,
    required this.currentRole,
    required this.onRoleSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chọn Vai Trò Trải Nghiệm',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Text(
            'Chuyển đổi giao diện ứng dụng di động theo các vai trò người dùng khác nhau:',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 16),
          _buildRoleOption(
            context,
            role: UserRole.manager,
            title: 'Chủ Trọ / Quản Lý',
            subtitle: 'Quản lý phòng, hóa đơn, ghi điện nước & doanh thu',
            icon: Icons.business_center_rounded,
            color: AppColors.primary,
          ),
          _buildRoleOption(
            context,
            role: UserRole.tenant,
            title: 'Khách Thuê Trọ',
            subtitle: 'Xem hợp đồng, hóa đơn VietQR & báo sự cố',
            icon: Icons.home_rounded,
            color: AppColors.success,
          ),
          _buildRoleOption(
            context,
            role: UserRole.technician,
            title: 'Kỹ Thuật Viên',
            subtitle: 'Xử lý danh sách sự cố & bảo trì thiết bị',
            icon: Icons.handyman_rounded,
            color: AppColors.warning,
          ),
          _buildRoleOption(
            context,
            role: UserRole.admin,
            title: 'Quản Trị Hệ Thống (Admin)',
            subtitle: 'Thống kê toàn bộ SaaS & quản lý người dùng',
            icon: Icons.admin_panel_settings_rounded,
            color: AppColors.danger,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleOption(
    BuildContext context, {
    required UserRole role,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = currentRole == role;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          onRoleSelected(role);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.08) : AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : AppColors.borderLight,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isSelected ? color : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: color, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
