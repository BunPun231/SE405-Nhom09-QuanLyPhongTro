import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/app_models.dart';

class MobileBottomNav extends StatelessWidget {
  final UserRole currentRole;
  final String currentPage;
  final Function(String) onNavigate;

  const MobileBottomNav({
    Key? key,
    required this.currentRole,
    required this.currentPage,
    required this.onNavigate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = _getItems();
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((item) => _buildNavItem(context, item)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, _NavItem item) {
    final isActive = currentPage == item.id;

    return Flexible(
      child: GestureDetector(
        onTap: () => onNavigate(item.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    item.icon,
                    size: 20,
                    color: isActive ? AppColors.primary : AppColors.textSecondaryLight,
                  ),
                  if ((item.badge ?? 0) > 0)
                    Positioned(
                      top: -4, right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: Text(
                          '${item.badge}',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? AppColors.primary : AppColors.textSecondaryLight,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_NavItem> _getItems() {
    switch (currentRole) {
      case UserRole.manager:
        return [
          _NavItem('dashboard', 'Tổng quan', Icons.home_rounded),
          _NavItem('rooms', 'Phòng trọ', Icons.meeting_room_rounded),
          _NavItem('invoices', 'Hóa đơn', Icons.receipt_long_rounded),
          _NavItem('profile', 'Tài khoản', Icons.person_rounded),
        ];
      case UserRole.tenant:
        return [
          _NavItem('home', 'Trang chủ', Icons.home_rounded),
          _NavItem('invoices', 'Hóa đơn', Icons.receipt_rounded),
          _NavItem('maintenance', 'Báo sự cố', Icons.handyman_rounded),
          _NavItem('profile', 'Tài khoản', Icons.person_rounded),
        ];
      case UserRole.technician:
        return [
          _NavItem('tasks', 'Công việc', Icons.assignment_rounded, badge: 3),
          _NavItem('equipment', 'Thiết bị', Icons.memory_rounded),
          _NavItem('profile', 'Tài khoản', Icons.person_rounded),
        ];
      case UserRole.admin:
        return [
          _NavItem('admin-dashboard', 'Dashboard', Icons.dashboard_rounded),
          _NavItem('admin-users', 'Tài khoản', Icons.people_alt_rounded),
          _NavItem('admin-subscriptions', 'Gói cước', Icons.shield_rounded),
          _NavItem('profile', 'Cá nhân', Icons.person_rounded),
        ];
    }
  }
}

class _NavItem {
  final String id;
  final String label;
  final IconData icon;
  final int? badge;
  _NavItem(this.id, this.label, this.icon, {this.badge});
}
