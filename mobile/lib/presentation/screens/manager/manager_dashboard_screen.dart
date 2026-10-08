import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/report_service.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────
String _fmtCurrency(double v) {
  if (v >= 1000000000) return '${(v / 1000000000).toStringAsFixed(1)}T đ';
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M đ';
  return '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';
}

String _fmtDate(String iso) {
  try {
    final d = DateTime.parse(iso).toLocal();
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso.length > 10 ? iso.substring(0, 10) : iso;
  }
}

Color _statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'PAID': return const Color(0xFF10B981);
    case 'PARTIAL': return const Color(0xFFF59E0B);
    default: return const Color(0xFFEF4444);
  }
}

String _statusLabel(String status) {
  switch (status.toUpperCase()) {
    case 'PAID': return 'Đã đóng';
    case 'PARTIAL': return 'Một phần';
    default: return 'Chưa TT';
  }
}

// ─── KPI Card Widget ──────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String? sub;
  final bool? trendUp;
  final String? trendValue;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.sub,
    this.trendUp,
    this.trendValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis)),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
        ]),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5)),
        const SizedBox(height: 6),
        if (trendValue != null)
          Row(children: [
            Icon(trendUp == true ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 13,
                color: trendUp == true ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
            const SizedBox(width: 3),
            Text(trendValue!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: trendUp == true ? const Color(0xFF16A34A) : const Color(0xFFDC2626))),
          ])
        else if (sub != null)
          Text(sub!, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
      ]),
    );
  }
}

// ─── Main Screen ─────────────────────────────────────────────────────────────
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await ReportService.getDashboardSummary();
      if (mounted) setState(() { _summary = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildSkeleton();
    if (_error != null) return _buildError();
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: AppColors.primary,
      child: _buildContent(),
    );
  }

  // ── Skeleton loading ─────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _skelBox(40, double.infinity),
      const SizedBox(height: 20),
      Row(children: [Expanded(child: _skelBox(90, double.infinity)), const SizedBox(width: 10), Expanded(child: _skelBox(90, double.infinity))]),
      const SizedBox(height: 10),
      Row(children: [Expanded(child: _skelBox(90, double.infinity)), const SizedBox(width: 10), Expanded(child: _skelBox(90, double.infinity))]),
      const SizedBox(height: 20),
      _skelBox(200, double.infinity),
      const SizedBox(height: 14),
      _skelBox(150, double.infinity),
    ]);
  }

  Widget _skelBox(double h, double w) => Container(
    height: h, width: w,
    margin: const EdgeInsets.only(bottom: 0),
    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
  );

  // ── Error state ──────────────────────────────────────────────────────────
  Widget _buildError() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.08), shape: BoxShape.circle),
        child: const Icon(Icons.error_outline_rounded, size: 36, color: AppColors.danger)),
    const SizedBox(height: 16),
    Text(_error ?? 'Đã xảy ra lỗi', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF475569), fontSize: 14)),
    const SizedBox(height: 16),
    ElevatedButton.icon(
      onPressed: _loadDashboardData,
      icon: const Icon(Icons.refresh_rounded, size: 16),
      label: const Text('Thử lại'),
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    ),
  ]));

  // ── Main content ─────────────────────────────────────────────────────────
  Widget _buildContent() {
    final s = _summary;
    final expectedRev = s?.expectedRevenue ?? 0;
    final collectedRev = s?.collectedRevenue ?? 0;
    final pendingDebt = s?.pendingDebt ?? 0;
    final rate = expectedRev > 0 ? ((collectedRev / expectedRev) * 100).clamp(0.0, 100.0) : 0.0;
    final rateInt = rate.round();
    final now = DateTime.now();
    const days = ['CN', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7'];

    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
      // Header
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Tổng quan hệ thống', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5)),
          Text('${days[now.weekday % 7]}, ${now.day}/${now.month}/${now.year}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ]),
        GestureDetector(
          onTap: _loadDashboardData,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF475569)),
          ),
        ),
      ]),
      const SizedBox(height: 20),

      // 4 KPI Cards (matching web 1:1)
      Row(children: [
        Expanded(child: _KpiCard(
          title: 'Doanh thu dự kiến',
          value: _fmtCurrency(expectedRev),
          icon: Icons.account_balance_wallet_rounded,
          iconBg: const Color(0xFFF3F4FF),
          iconColor: const Color(0xFF6366F1),
          trendValue: 'Đã thu: $rateInt%',
          trendUp: rateInt >= 80,
        )),
        const SizedBox(width: 10),
        Expanded(child: _KpiCard(
          title: 'Tỷ lệ lấp đầy',
          value: '${(s?.occupancyRate ?? 0).round()}%',
          icon: Icons.apartment_rounded,
          iconBg: const Color(0xFFECFDF5),
          iconColor: const Color(0xFF10B981),
          sub: '${s?.rentedRooms ?? 0}/${s?.totalRooms ?? 0} phòng thuê',
        )),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _KpiCard(
          title: 'HĐ sắp hết hạn',
          value: '${s?.expiringContractsCount ?? 0}',
          icon: Icons.description_rounded,
          iconBg: const Color(0xFFFFFBEB),
          iconColor: const Color(0xFFF59E0B),
          sub: 'Trong 30 ngày tới',
        )),
        const SizedBox(width: 10),
        Expanded(child: _KpiCard(
          title: 'HĐ chưa thanh toán',
          value: '${s?.unpaidInvoicesCount ?? 0}',
          icon: Icons.warning_amber_rounded,
          iconBg: const Color(0xFFFFF1F2),
          iconColor: const Color(0xFFF43F5E),
          sub: 'Nợ: ${_fmtCurrency(pendingDebt)}',
        )),
      ]),
      const SizedBox(height: 20),

      // Revenue card (Tài chính tháng này)
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Tài chính tháng này', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
              GestureDetector(
                onTap: () => widget.onNavigate('reports'),
                child: const Row(children: [
                  Text('Xem báo cáo', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Tiến độ thu tiền', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                Text('$rateInt%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (rate / 100).clamp(0, 1), minHeight: 10,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation(rateInt >= 80 ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(children: [
              _revBox('Dự kiến', expectedRev, const Color(0xFFF8FAFC), const Color(0xFF334155)),
              const SizedBox(width: 8),
              _revBox('Đã thu', collectedRev, const Color(0xFFECFDF5), const Color(0xFF065F46)),
              const SizedBox(width: 8),
              _revBox('Còn nợ', pendingDebt, const Color(0xFFFFF1F2), const Color(0xFF9F1239)),
            ]),
          ),
          // Recent invoices
          if (s != null && s.recentInvoices.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text('Hóa đơn gần đây', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
            ),
            ...s.recentInvoices.take(4).map((inv) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF8FAFC)))),
                child: Row(children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: _statusColor(inv.status), shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(inv.roomNumber != null ? 'Phòng ${inv.roomNumber}' : 'HĐ #${inv.invoiceId}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF334155))),
                    Text(inv.billingMonth, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(_fmtCurrency(inv.amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: _statusColor(inv.status).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                      child: Text(_statusLabel(inv.status), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _statusColor(inv.status))),
                    ),
                  ]),
                ]),
              ),
            )),
            const SizedBox(height: 12),
          ] else
            const SizedBox(height: 16),
        ]),
      ),
      const SizedBox(height: 16),

      // Action Required panel
      _buildActionRequired(s),
      const SizedBox(height: 16),

      // Recent Activities
      if (s != null && s.recentActivities.isNotEmpty) ...[
        _buildActivities(s.recentActivities),
        const SizedBox(height: 16),
      ],

      // Quick Actions
      _buildQuickActions(),
    ]);
  }

  Widget _revBox(String label, double value, Color bg, Color textColor) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Text(_fmtCurrency(value), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
      ]),
    ),
  );

  Widget _buildActionRequired(DashboardSummaryResult? s) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFF1F5F9)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Text('Cần xử lý', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
      ),
      if (s == null || (s.unpaidInvoicesCount == 0 && s.expiringContractsCount == 0 && s.pendingMeterReadingsCount == 0))
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(children: [
            Icon(Icons.check_circle_outline_rounded, size: 36, color: Color(0xFF10B981)),
            SizedBox(height: 8),
            Text('Không có việc cần xử lý', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
            Text('Hệ thống đang hoạt động bình thường', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ]),
        )
      else ...[
        if ((s.unpaidInvoicesCount) > 0)
          _actionItem(
            icon: Icons.warning_amber_rounded, iconColor: const Color(0xFFE11D48),
            bg: const Color(0xFFFFF1F2), border: const Color(0xFFFFCDD2),
            title: '${s.unpaidInvoicesCount} hóa đơn chưa thanh toán',
            sub: 'Tổng nợ: ${_fmtCurrency(s.pendingDebt)}',
            onTap: () => widget.onNavigate('invoices'),
          ),
        if ((s.expiringContractsCount) > 0)
          _actionItem(
            icon: Icons.access_time_rounded, iconColor: const Color(0xFFF59E0B),
            bg: const Color(0xFFFFFBEB), border: const Color(0xFFFDE68A),
            title: '${s.expiringContractsCount} hợp đồng sắp hết hạn',
            sub: 'Cần gia hạn trong 30 ngày',
            onTap: () => widget.onNavigate('contracts'),
          ),
        if ((s.pendingMeterReadingsCount) > 0)
          _actionItem(
            icon: Icons.bolt_rounded, iconColor: const Color(0xFF3B82F6),
            bg: const Color(0xFFEFF6FF), border: const Color(0xFFBFDBFE),
            title: '${s.pendingMeterReadingsCount} chỉ số chờ duyệt',
            sub: 'Ghi chỉ số điện nước',
            onTap: () => widget.onNavigate('utility-reading'),
          ),
        const SizedBox(height: 8),
      ],
    ]),
  );

  Widget _actionItem({required IconData icon, required Color iconColor, required Color bg, required Color border, required String title, required String sub, required VoidCallback onTap}) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
        child: Row(children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: iconColor)),
            Text(sub, style: TextStyle(fontSize: 11, color: iconColor.withValues(alpha: 0.7))),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: iconColor.withValues(alpha: 0.5)),
        ]),
      ),
    );

  Widget _buildActivities(List<RecentActivity> activities) => Container(
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFF1F5F9)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('HOẠT ĐỘNG GẦN ĐÂY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
      const SizedBox(height: 14),
      ...activities.take(3).toList().asMap().entries.map((e) {
        final act = e.value;
        final isLast = e.key == (activities.length < 3 ? activities.length - 1 : 2);
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2), shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5))),
            if (!isLast) Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
          ]),
          const SizedBox(width: 12),
          Expanded(child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(act.description.isNotEmpty ? act.description : act.action,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(_fmtDate(act.createdAt), style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            ]),
          )),
        ]);
      }),
    ]),
  );

  Widget _buildQuickActions() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF1E3A5F), Color(0xFF1E293B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Thao tác nhanh', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
      const SizedBox(height: 14),
      GridView.count(
        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.6,
        children: [
          _quickBtn(Icons.receipt_long_rounded, 'Tạo hóa đơn', 'invoices'),
          _quickBtn(Icons.person_add_rounded, 'Thêm khách thuê', 'tenants'),
          _quickBtn(Icons.description_rounded, 'Tạo hợp đồng', 'contracts'),
          _quickBtn(Icons.bolt_rounded, 'Ghi chỉ số', 'utility-reading'),
        ],
      ),
    ]),
  );

  Widget _quickBtn(IconData icon, String label, String page) => GestureDetector(
    onTap: () => widget.onNavigate(page),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.white),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white), overflow: TextOverflow.ellipsis)),
      ]),
    ),
  );
}
