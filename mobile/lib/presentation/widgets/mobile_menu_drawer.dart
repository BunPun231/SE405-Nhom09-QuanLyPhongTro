import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/app_models.dart';

class MobileMenuDrawer extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final UserRole currentRole;
  final String currentPage;
  final Function(String) onNavigate;
  final VoidCallback? onLogout;

  const MobileMenuDrawer({
    Key? key,
    required this.isOpen,
    required this.onClose,
    required this.currentRole,
    required this.currentPage,
    required this.onNavigate,
    this.onLogout,
  }) : super(key: key);

  List<_MenuSection> _getMenu() {
    switch (currentRole) {
      case UserRole.manager:
        return [
          _MenuSection('Quản lý chính', [
            _MenuItem('dashboard', 'Tổng quan', 'Doanh thu & lấp đầy', Icons.home_rounded),
            _MenuItem('motels', 'Dãy trọ & Tòa nhà', 'Quản lý cơ sở', Icons.business_rounded),
            _MenuItem('rooms', 'Phòng trọ', 'Danh sách & trạng thái', Icons.apartment_rounded),
            _MenuItem('tenants', 'Khách thuê', 'Hồ sơ & thông tin', Icons.people_alt_rounded),
          ]),
          _MenuSection('Vận hành', [
            _MenuItem('contracts', 'Hợp đồng', 'Thời hạn & cọc', Icons.description_rounded),
            _MenuItem('invoices', 'Hóa đơn & VietQR', 'Thu tiền hàng tháng', Icons.receipt_long_rounded),
            _MenuItem('maintenance', 'Bảo trì & Sự cố', 'Tiếp nhận & phân thợ', Icons.build_rounded),
            _MenuItem('utility-reading', 'Ghi số Điện Nước', 'Chỉ số hàng tháng', Icons.bolt_rounded),
          ]),
          _MenuSection('Tài sản & Dịch vụ', [
            _MenuItem('equipment', 'Thiết bị phòng', 'Tài sản tòa nhà', Icons.inventory_2_rounded),
            _MenuItem('services', 'Đơn giá Dịch vụ', 'Điện, nước, wifi', Icons.settings_rounded),
          ]),
          _MenuSection('Báo cáo & Tương tác', [
            _MenuItem('broadcast', 'Gửi thông báo', 'SMS, Zalo, App Push', Icons.send_rounded),
            _MenuItem('analytics', 'Thống kê & Báo cáo', 'Báo cáo doanh thu & lấp đầy', Icons.bar_chart_rounded),
            _MenuItem('audit-log', 'Nhật ký thao tác', 'Lịch sử hệ thống', Icons.history_rounded),
            _MenuItem('profile', 'Tài khoản', 'Hồ sơ cá nhân', Icons.person_rounded),
          ]),
        ];
      case UserRole.tenant:
        return [
          _MenuSection('Phòng trọ', [
            _MenuItem('home', 'Trang chủ', 'Thông tin phòng của tôi', Icons.home_rounded),
            _MenuItem('invoices', 'Hóa đơn', 'Thanh toán VietQR', Icons.receipt_rounded),
            _MenuItem('maintenance', 'Báo sự cố', 'Gửi yêu cầu sửa chữa', Icons.handyman_rounded),
            _MenuItem('contract', 'Hợp đồng', 'Thông tin hợp đồng thuê', Icons.description_rounded),
            _MenuItem('profile', 'Tài khoản', 'Hồ sơ cá nhân', Icons.person_rounded),
          ]),
        ];
      case UserRole.technician:
        return [
          _MenuSection('Công việc', [
            _MenuItem('tasks', 'Danh sách công việc', 'Sự cố được giao', Icons.assignment_rounded),
            _MenuItem('equipment', 'Thiết bị', 'Danh mục & bảo trì', Icons.memory_rounded),
            _MenuItem('profile', 'Tài khoản', 'Hồ sơ cá nhân', Icons.person_rounded),
          ]),
        ];
      case UserRole.admin:
        return [
          _MenuSection('Hệ thống', [
            _MenuItem('admin-dashboard', 'SaaS Overview', 'Thống kê toàn hệ thống', Icons.dashboard_rounded),
            _MenuItem('admin-users', 'Người dùng', 'Quản lý tài khoản', Icons.people_alt_rounded),
            _MenuItem('admin-subscriptions', 'Gói cước', 'Quản lý subscription', Icons.shield_rounded),
          ]),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isOpen) return const SizedBox.shrink();

    final menu = _getMenu();

    return Stack(
      children: [
        // Backdrop
        GestureDetector(
          onTap: onClose,
          child: Container(color: Colors.black.withValues(alpha: 0.5)),
        ),
        // Drawer panel
        Positioned(
          left: 0, top: 0, bottom: 0,
          width: MediaQuery.of(context).size.width * 0.82,
          child: Material(
            color: Colors.white,
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.home_work_rounded, color: AppColors.primary, size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Text('Smart Room Rental', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        GestureDetector(
                          onTap: onClose,
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Menu Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      children: menu.map((section) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8, top: 12, bottom: 6),
                              child: Text(
                                section.title.toUpperCase(),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight, letterSpacing: 1),
                              ),
                            ),
                            ...section.items.map((item) {
                              final isActive = currentPage == item.id;
                              return InkWell(
                                onTap: () {
                                  onNavigate(item.id);
                                  onClose();
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  margin: const EdgeInsets.only(bottom: 4),
                                  decoration: BoxDecoration(
                                    color: isActive ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36, height: 36,
                                        decoration: BoxDecoration(
                                          color: isActive ? AppColors.primary.withValues(alpha: 0.15) : AppColors.backgroundLight,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(item.icon, size: 18, color: isActive ? AppColors.primary : AppColors.textSecondaryLight),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item.label, style: TextStyle(fontSize: 13, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? AppColors.primary : AppColors.textPrimaryLight)),
                                            Text(item.desc, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.chevron_right_rounded, size: 16, color: isActive ? AppColors.primary : AppColors.textSecondaryLight),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  // Logout Button
                  if (onLogout != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: InkWell(
                        onTap: () {
                          onClose();
                          onLogout!();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.logout_rounded, color: AppColors.danger, size: 18),
                              SizedBox(width: 10),
                              Text('Đăng Xuất', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.danger)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuSection {
  final String title;
  final List<_MenuItem> items;
  _MenuSection(this.title, this.items);
}

class _MenuItem {
  final String id;
  final String label;
  final String desc;
  final IconData icon;
  _MenuItem(this.id, this.label, this.desc, this.icon);
}
