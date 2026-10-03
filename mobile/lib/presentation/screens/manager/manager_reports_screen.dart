import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/report_service.dart';

class ManagerReportsScreen extends StatefulWidget {
  const ManagerReportsScreen({Key? key}) : super(key: key);

  @override
  State<ManagerReportsScreen> createState() => _ManagerReportsScreenState();
}

class _ManagerReportsScreenState extends State<ManagerReportsScreen> {
  DashboardSummaryResult? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    final data = await ReportService.getDashboardSummary();
    if (mounted) {
      setState(() {
        _summary = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final expected = _summary?.expectedRevenue ?? 0;
    final collected = _summary?.collectedRevenue ?? 0;
    final debt = _summary?.pendingDebt ?? 0;
    final occRate = _summary?.occupancyRate ?? 0;

    final expectedStr = expected.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    final collectedStr = collected.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    final debtStr = debt.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadReportData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Revenue Header Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tổng doanh thu dự kiến tháng này', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 6),
                          Text('${expectedStr}đ', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _headerStat('Đã thu', '${collectedStr}đ', Colors.greenAccent),
                              _headerStat('Còn nợ', '${debtStr}đ', Colors.amberAccent),
                              _headerStat('Công suất', '${(occRate * 100).toStringAsFixed(0)}%', Colors.white),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('Tổng quan phòng trọ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    _buildReportCategoryCard('Tổng số phòng', '${_summary?.totalRooms ?? 0} phòng', 1.0, Colors.blue),
                    _buildReportCategoryCard('Phòng đang thuê', '${_summary?.rentedRooms ?? 0} phòng', occRate, Colors.green),
                    _buildReportCategoryCard('Phòng trống', '${_summary?.availableRooms ?? 0} phòng', 1 - occRate, Colors.orange),

                    const SizedBox(height: 20),
                    const Text('Hoạt động gần đây', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    if ((_summary?.recentActivities ?? []).isEmpty)
                      const Text('Chưa có nhật ký hoạt động gần đây', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13))
                    else
                      ..._summary!.recentActivities.map((act) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.history_rounded, color: AppColors.primary),
                              title: Text(act.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              subtitle: Text(act.createdAt, style: const TextStyle(fontSize: 11)),
                            ),
                          )),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _headerStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildReportCategoryCard(String title, String amount, double ratio, Color color) {
    final validRatio = ratio.isNaN || ratio.isInfinite ? 0.0 : ratio.clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderLight)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(amount, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: validRatio, minHeight: 6, backgroundColor: Colors.grey.shade100, valueColor: AlwaysStoppedAnimation(color)),
          ),
        ],
      ),
    );
  }
}
