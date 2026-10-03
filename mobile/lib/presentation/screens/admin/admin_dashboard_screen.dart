import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/report_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  DashboardSummaryResult? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await ReportService.getDashboardSummary();
      if (mounted) {
        setState(() {
          _summary = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadAdminData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hệ Thống SaaS Smart Room Rental', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _AdminStat(title: 'Tổng Số Phòng', value: '${_summary?.totalRooms ?? 0}'),
                            _AdminStat(title: 'Đã Cho Thuê', value: '${_summary?.rentedRooms ?? 0}'),
                            _AdminStat(title: 'Hợp Đồng Active', value: '${_summary?.activeContractsCount ?? 0}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Tổng quan doanh thu hệ thống', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: const Icon(Icons.monetization_on_rounded, color: AppColors.success, size: 32),
                      title: const Text('Doanh Thu Dự Kiến', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
                      subtitle: Text(
                        '${(_summary?.expectedRevenue ?? 0).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textPrimaryLight),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _AdminStat extends StatelessWidget {
  final String title;
  final String value;
  const _AdminStat({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}
