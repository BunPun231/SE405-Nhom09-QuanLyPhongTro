import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/report_service.dart';

class ManagerDashboardScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const ManagerDashboardScreen({
    Key? key,
    required this.onNavigate,
  }) : super(key: key);

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  DashboardSummaryResult? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
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

  static const _quickActions = [
    _QuickAction('Ghi điện nước', 'Chỉ số tháng này', Icons.bolt_rounded, 'utility-reading'),
    _QuickAction('Thu tiền QR', 'Hóa đơn cần thu', Icons.qr_code_2_rounded, 'invoices'),
    _QuickAction('Phòng trọ', 'Xem phòng', Icons.apartment_rounded, 'rooms'),
    _QuickAction('Hợp đồng', 'Quản lý hợp đồng', Icons.description_rounded, 'contracts'),
  ];

  @override
  Widget build(BuildContext context) {
    final expectedRev = _summary?.expectedRevenue ?? 47300000;
    final collectedRev = _summary?.collectedRevenue ?? 34500000;
    final pendingDebt = _summary?.pendingDebt ?? 12800000;
    final rate = expectedRev > 0 ? (collectedRev / expectedRev).clamp(0.0, 1.0) : 0.73;

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BẢNG ĐIỀU KHIỂN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight, letterSpacing: 1.2)),
                  SizedBox(height: 2),
                  Text('Tổng quan', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight)),
                  Text('Mọi thứ bạn cần, trong một nơi.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                ],
              ),
              GestureDetector(
                onTap: () {
                  _loadDashboardData();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã đồng bộ dữ liệu mới nhất từ máy chủ')));
                },
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textPrimaryLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Revenue Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                Positioned(right: -40, top: -50,
                  child: Container(width: 130, height: 130, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1)))),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Doanh thu dự kiến', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                          child: Text('Tháng ${_isLoading ? '...' : '10 / 2026'}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          expectedRev.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.'),
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -1),
                        ),
                        const SizedBox(width: 4),
                        const Padding(padding: EdgeInsets.only(bottom: 4), child: Text('đ', style: TextStyle(color: Colors.white70, fontSize: 16))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tiến độ thu tiền', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('${(rate * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 6,
                        color: Colors.white.withValues(alpha: 0.2),
                        child: FractionallySizedBox(
                          widthFactor: rate,
                          alignment: Alignment.centerLeft,
                          child: Container(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Đã thu', style: TextStyle(color: Colors.white54, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text('${collectedRev.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                        Container(width: 1, height: 36, color: Colors.white24),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('Chờ thanh toán', style: TextStyle(color: Colors.white54, fontSize: 11)),
                              const SizedBox(height: 4),
                              Text('${pendingDebt.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Quick Actions Section
          const Text('Truy cập nhanh', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.7,
            children: _quickActions.map((a) => GestureDetector(
              onTap: () => widget.onNavigate(a.page),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(8)),
                      child: Icon(a.icon, size: 16, color: AppColors.primary),
                    ),
                    const SizedBox(height: 6),
                    Text(a.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(a.detail, style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final String label;
  final String detail;
  final IconData icon;
  final String page;

  const _QuickAction(this.label, this.detail, this.icon, this.page);
}
