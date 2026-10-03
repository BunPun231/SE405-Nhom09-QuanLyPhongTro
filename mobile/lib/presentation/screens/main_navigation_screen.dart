import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/app_models.dart';
import '../../core/network/api_client.dart';
import '../widgets/mobile_header.dart';
import '../widgets/mobile_bottom_nav.dart';
import '../widgets/mobile_menu_drawer.dart';
import 'auth/login_screen.dart';

// Manager Screens
import 'manager/manager_dashboard_screen.dart';
import 'manager/manager_rooms_screen.dart';
import 'manager/manager_invoices_screen.dart';
import 'manager/manager_utility_reading_screen.dart';
import 'manager/manager_maintenance_screen.dart';
import 'manager/manager_tenants_screen.dart';
import 'manager/manager_contracts_screen.dart';
import 'manager/manager_services_screen.dart';
import 'manager/manager_notifications_screen.dart';
import 'manager/manager_profile_screen.dart';
import 'manager/manager_motels_screen.dart';
import 'manager/manager_reports_screen.dart';
import 'manager/manager_audit_log_screen.dart';

// Tenant Screens
import 'tenant/tenant_home_screen.dart';
import 'tenant/tenant_invoices_screen.dart';
import 'tenant/tenant_maintenance_screen.dart';
import 'tenant/tenant_contract_screen.dart';
import 'tenant/tenant_profile_screen.dart';

// Technician Screens
import 'technician/technician_tasks_screen.dart';
import 'technician/technician_equipment_screen.dart';
import 'technician/technician_profile_screen.dart';

// Admin Screens
import 'admin/admin_dashboard_screen.dart';
import 'admin/admin_users_screen.dart';
import 'admin/admin_subscriptions_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final UserRole initialRole;
  final String userName;

  const MainNavigationScreen({
    Key? key,
    this.initialRole = UserRole.tenant,
    this.userName = 'Người dùng',
  }) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late UserRole _currentRole;
  late String _currentPage;
  bool _isMenuOpen = false;

  final List<NotificationItem> _notifications = [
    NotificationItem(id: '1', title: 'Khách thuê P101 vừa thanh toán', desc: 'Tiền phòng tháng 10: 4.150.000đ qua VietQR', time: '5 phút trước'),
    NotificationItem(id: '2', title: 'Phòng P205 báo sự cố mới', desc: 'Vòi nước chậu rửa rò rỉ mạnh', time: '30 phút trước'),
    NotificationItem(id: '3', title: 'Hợp đồng phòng P102 sắp hết hạn', desc: 'Hết hạn vào 20/01/2027', time: '2 giờ trước', unread: false),
  ];

  @override
  void initState() {
    super.initState();
    _currentRole = widget.initialRole;
    _currentPage = _defaultPageForRole(widget.initialRole);
  }

  String _defaultPageForRole(UserRole role) {
    switch (role) {
      case UserRole.manager: return 'dashboard';
      case UserRole.tenant: return 'home';
      case UserRole.technician: return 'tasks';
      case UserRole.admin: return 'admin-dashboard';
    }
  }

  Future<void> _handleLogout() async {
    await ApiClient.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    await prefs.remove('user_fullname');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          onLoginSuccess: (role, userName) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => MainNavigationScreen(
                  initialRole: role,
                  userName: userName,
                ),
              ),
            );
          },
        ),
      ),
      (route) => false,
    );
  }

  void _navigateTo(String page) {
    if (page == 'quick-action') {
      _showQuickActionSheet();
      return;
    }
    setState(() => _currentPage = page);
  }


  void _showQuickActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Tạo mới nhanh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _quickActionTile(context, Icons.meeting_room_rounded, 'Thêm phòng mới', 'rooms'),
          _quickActionTile(context, Icons.receipt_long_rounded, 'Lập hóa đơn', 'invoices'),
          _quickActionTile(context, Icons.bolt_rounded, 'Ghi điện nước', 'utility-reading'),
          _quickActionTile(context, Icons.people_alt_rounded, 'Thêm khách thuê', 'tenants'),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _quickActionTile(BuildContext context, IconData icon, String label, String page) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFF2563EB).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
      onTap: () { Navigator.pop(context); _navigateTo(page); },
    );
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Thông Báo Mới', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          ..._notifications.map((n) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: n.unread ? const Color(0xFF2563EB).withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
              child: Icon(Icons.notifications_active_rounded, color: n.unread ? const Color(0xFF2563EB) : Colors.grey, size: 18),
            ),
            title: Text(n.title, style: TextStyle(fontWeight: n.unread ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
            subtitle: Text(n.desc, style: const TextStyle(fontSize: 11)),
            trailing: Text(n.time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          )),
        ]),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentRole) {
      case UserRole.manager:
        switch (_currentPage) {
          case 'dashboard': return ManagerDashboardScreen(onNavigate: _navigateTo);
          case 'motels': return const ManagerMotelsScreen();
          case 'rooms': return const ManagerRoomsScreen();
          case 'tenants': return const ManagerTenantsScreen();
          case 'contracts': return const ManagerContractsScreen();
          case 'invoices': return const ManagerInvoicesScreen();
          case 'utility-reading': return const ManagerUtilityReadingScreen();
          case 'maintenance': return const ManagerMaintenanceScreen();
          case 'services': return const ManagerServicesScreen();
          case 'broadcast': return const ManagerNotificationsScreen();
          case 'analytics': return const ManagerReportsScreen();
          case 'audit-log': return const ManagerAuditLogScreen();
          case 'profile': return ManagerProfileScreen(onLogout: _handleLogout);
          default: return ManagerDashboardScreen(onNavigate: _navigateTo);
        }
      case UserRole.tenant:
        switch (_currentPage) {
          case 'home': return TenantHomeScreen(onNavigateTab: (i) { const pages = ['home','invoices','maintenance','contract','profile']; if (i < pages.length) _navigateTo(pages[i]); });
          case 'invoices': return const TenantInvoicesScreen();
          case 'maintenance': return const TenantMaintenanceScreen();
          case 'contract': return const TenantContractScreen();
          case 'profile': return const TenantProfileScreen();
          default: return TenantHomeScreen(onNavigateTab: (i) { const pages = ['home','invoices','maintenance','contract','profile']; if (i < pages.length) _navigateTo(pages[i]); });
        }
      case UserRole.technician:
        switch (_currentPage) {
          case 'tasks': return const TechnicianTasksScreen();
          case 'equipment': return const TechnicianEquipmentScreen();
          case 'profile': return const TechnicianProfileScreen();
          default: return const TechnicianTasksScreen();
        }
      case UserRole.admin:
        switch (_currentPage) {
          case 'admin-dashboard': return const AdminDashboardScreen();
          case 'admin-users': return const AdminUsersScreen();
          case 'admin-subscriptions': return const AdminSubscriptionsScreen();
          default: return const AdminDashboardScreen();
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Column(
            children: [
              MobileHeader(
                currentRole: _currentRole,
                userName: widget.userName,
                onOpenMenu: () => setState(() => _isMenuOpen = true),
                onOpenNotifications: _showNotificationsSheet,
                unreadCount: _notifications.where((n) => n.unread).length,
              ),
              // Main body
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: 64 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: _buildBody(),
                ),
              ),
            ],
          ),
          // Bottom Nav overlaid
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: MobileBottomNav(
              currentRole: _currentRole,
              currentPage: _currentPage,
              onNavigate: _navigateTo,
            ),
          ),
          // Menu Drawer
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _isMenuOpen
                ? MobileMenuDrawer(
                    key: const ValueKey('menu'),
                    isOpen: _isMenuOpen,
                    onClose: () => setState(() => _isMenuOpen = false),
                    currentRole: _currentRole,
                    currentPage: _currentPage,
                    onNavigate: _navigateTo,
                    onLogout: _handleLogout,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
