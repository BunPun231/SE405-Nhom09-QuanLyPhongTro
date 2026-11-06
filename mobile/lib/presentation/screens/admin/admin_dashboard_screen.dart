import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/admin_service.dart';
import 'admin_users_screen.dart';

/// Tổng quan SaaS cho Admin: số lượng chủ trọ theo trạng thái và các chủ trọ đăng ký mới nhất.
class AdminDashboardScreen extends StatefulWidget {
  final void Function(String page)? onNavigate;

  const AdminDashboardScreen({Key? key, this.onNavigate}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _total = 0;
  int _active = 0;
  int _locked = 0;
  List<ManagerResult> _recent = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Đếm chính xác theo từng trạng thái (không suy ra từ vài bản ghi đầu).
      final results = await Future.wait([
        AdminService.getManagers(size: 5),
        AdminService.getManagers(status: 'ACTIVE', size: 1),
        AdminService.getManagers(status: 'LOCKED', size: 1),
      ]);
      if (!mounted) return;
      setState(() {
        _recent = results[0].content;
        _total = results[0].totalElements;
        _active = results[1].totalElements;
        _locked = results[2].totalElements;
        _error = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ListView(children: [
                  const SizedBox(height: 120),
                  Center(child: Text(_error!, style: const TextStyle(color: AppColors.danger))),
                  Center(child: TextButton(onPressed: _load, child: const Text('Thử lại'))),
                ])
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hệ Thống SaaS Smart Room Rental',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('Giám sát chủ trọ và quyền truy cập toàn hệ thống',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _AdminStat(title: 'Tổng chủ trọ', value: '$_total')),
                              Expanded(child: _AdminStat(title: 'Hoạt động', value: '$_active', color: const Color(0xFF34D399))),
                              Expanded(child: _AdminStat(title: 'Bị khóa', value: '$_locked', color: const Color(0xFFF87171))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Chủ trọ đăng ký mới nhất', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        if (widget.onNavigate != null)
                          TextButton(onPressed: () => widget.onNavigate!('admin-users'), child: const Text('Xem tất cả')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_recent.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(child: Text('Chưa có chủ trọ nào đăng ký', style: TextStyle(color: AppColors.textSecondaryLight))),
                      )
                    else
                      ..._recent.map((m) => ManagerCard(manager: m)),
                  ],
                ),
    );
  }
}

class _AdminStat extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _AdminStat({required this.title, required this.value, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}
