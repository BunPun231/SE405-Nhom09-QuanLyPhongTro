import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/report_service.dart';
import '../../../core/services/motel_service.dart';

// ─── helpers ─────────────────────────────────────────────────────────────────
String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

// ─── Main Screen ─────────────────────────────────────────────────────────────
class ManagerReportsScreen extends StatefulWidget {
  const ManagerReportsScreen({Key? key}) : super(key: key);
  @override State<ManagerReportsScreen> createState() => _ManagerReportsScreenState();
}

enum _ReportTab { revenue, occupancy, debt }

class _ManagerReportsScreenState extends State<ManagerReportsScreen> {
  _ReportTab _tab = _ReportTab.revenue;
  List<MotelResult> _motels = [];
  int? _selectedMotelId;
  int _year = DateTime.now().year;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? _revenueData;
  Map<String, dynamic>? _occupancyData;
  Map<String, dynamic>? _debtData;

  @override
  void initState() {
    super.initState();
    _loadMotels();
  }

  Future<void> _loadMotels() async {
    try {
      final res = await MotelService.list(size: 50);
      if (mounted) {
        setState(() {
          _motels = res.content;
          if (res.content.isNotEmpty) _selectedMotelId = res.content.first.id;
        });
        _fetchData();
      }
    } catch (_) {}
  }

  Future<void> _fetchData() async {
    if (_selectedMotelId == null) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      if (_tab == _ReportTab.revenue) {
        _revenueData = await ReportService.getRevenue(_selectedMotelId!, _year);
      } else if (_tab == _ReportTab.occupancy) {
        _occupancyData = await ReportService.getOccupancy(_selectedMotelId!);
      } else {
        _debtData = await ReportService.getDebt(_selectedMotelId!);
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton(onPressed: _fetchData, backgroundColor: AppColors.primary, elevation: 2, child: const Icon(Icons.refresh_rounded, color: Colors.white)),
      body: Column(children: [
        // ── Controls ────────────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(children: [
            // Motel + Year filters
            Row(children: [
              if (_motels.isNotEmpty) Expanded(child: _dropFilter<int?>(
                value: _selectedMotelId,
                items: _motels.map((m) => DropdownMenuItem<int?>(value: m.id, child: Text(m.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) { setState(() => _selectedMotelId = v); _fetchData(); },
              )),
              if (_motels.isNotEmpty && _tab == _ReportTab.revenue) const SizedBox(width: 8),
              if (_tab == _ReportTab.revenue) _dropFilter<int>(
                value: _year,
                items: [2024, 2025, 2026, 2027].map((y) => DropdownMenuItem(value: y, child: Text('Năm $y', style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (v) { if (v != null) { setState(() => _year = v); _fetchData(); } },
              ),
            ]),
            const SizedBox(height: 10),
            // Tab bar
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                _tabBtn(_ReportTab.revenue, Icons.trending_up_rounded, 'Doanh thu'),
                _tabBtn(_ReportTab.occupancy, Icons.apartment_rounded, 'Công suất'),
                _tabBtn(_ReportTab.debt, Icons.credit_card_off_rounded, 'Công nợ'),
              ]),
            ),
          ]),
        ),
        // ── Content ─────────────────────────────────────────────────────────
        Expanded(child: RefreshIndicator(
          onRefresh: _fetchData,
          color: AppColors.primary,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
              : _error != null
                  ? _buildError()
                  : _buildContent(),
        )),
      ]),
    );
  }

  Widget _dropFilter<T>({required T value, required List<DropdownMenuItem<T>> items, required void Function(T?) onChanged}) => Container(
    height: 38,
    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(10), color: Colors.white),
    child: DropdownButtonHideUnderline(child: DropdownButton<T>(
      isExpanded: true, value: value,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      borderRadius: BorderRadius.circular(10),
      style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
      items: items, onChanged: onChanged,
    )),
  );

  Widget _tabBtn(_ReportTab tab, IconData icon, String label) {
    final active = _tab == tab;
    return Expanded(child: GestureDetector(
      onTap: () { setState(() => _tab = tab); _fetchData(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))] : [],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: active ? AppColors.primary : AppColors.textSecondaryLight),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.bold : FontWeight.normal, color: active ? AppColors.primary : AppColors.textSecondaryLight)),
        ]),
      ),
    ));
  }

  Widget _buildError() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
    const SizedBox(height: 12),
    Text(_error ?? '', style: const TextStyle(color: AppColors.danger), textAlign: TextAlign.center),
    const SizedBox(height: 12),
    ElevatedButton.icon(onPressed: _fetchData, icon: const Icon(Icons.refresh), label: const Text('Thử lại'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white)),
  ]));

  Widget _buildContent() {
    switch (_tab) {
      case _ReportTab.revenue: return _buildRevenue();
      case _ReportTab.occupancy: return _buildOccupancy();
      case _ReportTab.debt: return _buildDebt();
    }
  }

  // ── Revenue Tab ────────────────────────────────────────────────────────────
  Widget _buildRevenue() {
    final data = _revenueData;
    if (data == null) return _buildNoData('Chưa có dữ liệu doanh thu');

    final totalProjected = (data['totalProjected'] as num?)?.toDouble() ?? 0;
    final totalActual = (data['totalActual'] as num?)?.toDouble() ?? 0;
    final collectionRate = (data['collectionRate'] as num?)?.toDouble() ?? 0;
    final monthly = (data['monthly'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Summary cards
        Row(children: [
          _summaryCard('Dự kiến cả năm', '${_fmt(totalProjected)}đ', AppColors.primary),
          const SizedBox(width: 10),
          _summaryCard('Thực thu cả năm', '${_fmt(totalActual)}đ', AppColors.success),
        ]),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Tỷ lệ thu hồi', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
            const SizedBox(height: 6),
            Text('${collectionRate.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: (collectionRate / 100).clamp(0, 1), minHeight: 8, backgroundColor: const Color(0xFFF1F5F9), valueColor: const AlwaysStoppedAnimation(Color(0xFF7C3AED)))),
          ]),
        ),
        const SizedBox(height: 20),
        // Monthly chart (progress bars)
        const Text('Doanh thu theo tháng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        if (monthly.isEmpty)
          _buildNoData('Chưa có dữ liệu theo tháng')
        else
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)]),
            child: Column(children: monthly.asMap().entries.map((e) {
              final m = e.value as Map<String, dynamic>;
              final monthNum = (m['month'] as num?)?.toInt() ?? (e.key + 1);
              final projected = (m['projected'] as num?)?.toDouble() ?? 0;
              final actual = (m['actual'] as num?)?.toDouble() ?? 0;
              final maxVal = [projected, actual].reduce((a, b) => a > b ? a : b);
              final projRatio = maxVal > 0 ? (projected / maxVal).clamp(0.0, 1.0) : 0.0;
              final actualRatio = maxVal > 0 ? (actual / maxVal).clamp(0.0, 1.0) : 0.0;

              return Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: BoxDecoration(border: e.key < monthly.length - 1 ? const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))) : null),
                child: Row(children: [
                  SizedBox(width: 28, child: Text('T$monthNum', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight))),
                  const SizedBox(width: 10),
                  Expanded(child: Column(children: [
                    Row(children: [
                      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: projRatio, minHeight: 6, backgroundColor: const Color(0xFFF1F5F9), valueColor: const AlwaysStoppedAnimation(Color(0xFFA78BFA))))),
                      const SizedBox(width: 8),
                      SizedBox(width: 70, child: Text('${_fmt(projected)}đ', style: const TextStyle(fontSize: 9, color: AppColors.textSecondaryLight), textAlign: TextAlign.right)),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: actualRatio, minHeight: 6, backgroundColor: const Color(0xFFF1F5F9), valueColor: const AlwaysStoppedAnimation(AppColors.success)))),
                      const SizedBox(width: 8),
                      SizedBox(width: 70, child: Text('${_fmt(actual)}đ', style: const TextStyle(fontSize: 9, color: AppColors.success, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
                    ]),
                  ])),
                ]),
              );
            }).toList()),
          ),
        const SizedBox(height: 12),
        // Legend
        Row(children: [
          _legendDot(const Color(0xFFA78BFA), 'Dự kiến'),
          const SizedBox(width: 16),
          _legendDot(AppColors.success, 'Thực thu'),
        ]),
      ]),
    );
  }

  // ── Occupancy Tab ──────────────────────────────────────────────────────────
  Widget _buildOccupancy() {
    final data = _occupancyData;
    if (data == null) return _buildNoData('Chưa có dữ liệu công suất');

    final totalRooms = (data['totalRooms'] as num?)?.toInt() ?? 0;
    final rentedRooms = (data['rentedRooms'] as num?)?.toInt() ?? 0;
    final depositedRooms = (data['depositedRooms'] as num?)?.toInt() ?? 0;
    final availableRooms = (data['availableRooms'] as num?)?.toInt() ?? 0;
    final repairingRooms = (data['repairingRooms'] as num?)?.toInt() ?? 0;
    final occupancyRate = (data['occupancyRate'] as num?)?.toDouble() ?? 0;
    final emptyRooms = (data['emptyRooms'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Stat cards row
        Row(children: [
          _summaryCard('Tổng phòng', '$totalRooms phòng', const Color(0xFF1E293B), icon: Icons.apartment_rounded),
          const SizedBox(width: 10),
          _summaryCard('Đang thuê', '$rentedRooms phòng', const Color(0xFF3B82F6), icon: Icons.people_rounded),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _summaryCard('Đặt cọc', '$depositedRooms phòng', const Color(0xFF7C3AED), icon: Icons.lock_outline_rounded),
          const SizedBox(width: 10),
          _summaryCard('Còn trống', '$availableRooms phòng', AppColors.success, icon: Icons.door_back_door_outlined),
        ]),
        const SizedBox(height: 20),
        // Occupancy rate donut (represented as circular progress)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFF1F5F9)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)]),
          child: Row(children: [
            // Custom circular indicator
            SizedBox(width: 100, height: 100, child: Stack(alignment: Alignment.center, children: [
              SizedBox(width: 100, height: 100, child: CircularProgressIndicator(
                value: (occupancyRate / 100).clamp(0, 1),
                strokeWidth: 12,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              )),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${occupancyRate.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const Text('Lấp đầy', style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
              ]),
            ])),
            const SizedBox(width: 20),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _occupancyRow('Đang thuê', rentedRooms, totalRooms, const Color(0xFF10B981)),
              const SizedBox(height: 8),
              _occupancyRow('Đặt cọc', depositedRooms, totalRooms, const Color(0xFF7C3AED)),
              const SizedBox(height: 8),
              _occupancyRow('Còn trống', availableRooms, totalRooms, const Color(0xFF3B82F6)),
              if (repairingRooms > 0) ...[
                const SizedBox(height: 8),
                _occupancyRow('Sửa chữa', repairingRooms, totalRooms, AppColors.warning),
              ],
            ])),
          ]),
        ),
        // Empty rooms list
        if (emptyRooms.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(children: [
            const Text('Phòng trống', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Text('${emptyRooms.length}', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)]),
            child: Column(children: emptyRooms.asMap().entries.map((e) {
              final room = e.value as Map<String, dynamic>;
              final rn = room['roomNumber'] ?? '-';
              final floor = room['floor'] ?? '-';
              final price = (room['basePrice'] as num?)?.toDouble() ?? 0;
              return Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(border: e.key < emptyRooms.length - 1 ? const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))) : null),
                child: Row(children: [
                  const Icon(Icons.door_back_door_outlined, size: 18, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Phòng $rn', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('Tầng $floor', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                  ])),
                  Text('${_fmt(price)}đ/tháng', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ]),
              );
            }).toList()),
          ),
        ],
      ]),
    );
  }

  Widget _occupancyRow(String label, int count, int total, Color color) {
    final ratio = total > 0 ? count / total : 0.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight))),
        Text('$count phòng', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
      ]),
      const SizedBox(height: 3),
      ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: ratio.clamp(0, 1), minHeight: 5, backgroundColor: const Color(0xFFF1F5F9), valueColor: AlwaysStoppedAnimation(color))),
    ]);
  }

  // ── Debt Tab ───────────────────────────────────────────────────────────────
  Widget _buildDebt() {
    final data = _debtData;
    if (data == null) return _buildNoData('Chưa có dữ liệu công nợ');

    final totalDebt = (data['totalDebt'] as num?)?.toDouble() ?? 0;
    final debtorCount = (data['debtorCount'] as num?)?.toInt() ?? 0;
    final entries = (data['entries'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: const Border(left: BorderSide(color: Color(0xFFFCA5A5), width: 4)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Tổng công nợ', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
              const SizedBox(height: 4),
              Text('${_fmt(totalDebt)}đ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFE11D48))),
            ]),
          )),
          const SizedBox(width: 10),
          Expanded(child: _summaryCard('Số hóa đơn nợ', '$debtorCount HĐ', const Color(0xFF1E293B), icon: Icons.receipt_outlined)),
        ]),
        const SizedBox(height: 20),
        const Text('Chi tiết công nợ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
        const SizedBox(height: 10),
        if (entries.isEmpty)
          _buildNoData('Không có công nợ nào')
        else
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)]),
            child: Column(children: entries.asMap().entries.map((e) {
              final entry = e.value as Map<String, dynamic>;
              final roomNumber = entry['roomNumber'] ?? '-';
              final billingMonth = entry['billingMonth'] as String?;
              final debtAmount = (entry['debtAmount'] as num?)?.toDouble() ?? 0;
              final daysOverdue = (entry['daysOverdue'] as num?)?.toInt() ?? 0;
              final agingBucket = entry['agingBucket'] as String? ?? '';

              Color agingColor; String agingLabel;
              switch (agingBucket) {
                case 'BAD_DEBT': agingColor = AppColors.danger; agingLabel = 'Nợ xấu'; break;
                case 'OVERDUE': agingColor = AppColors.warning; agingLabel = 'Quá hạn'; break;
                default: agingColor = AppColors.textSecondaryLight; agingLabel = 'Mới';
              }

              String monthStr = '-';
              if (billingMonth != null && billingMonth.isNotEmpty) {
                try { final d = DateTime.parse(billingMonth); monthStr = 'Tháng ${d.month}/${d.year}'; } catch (_) { monthStr = billingMonth.substring(0, 7); }
              }

              return Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(border: e.key < entries.length - 1 ? const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))) : null),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Phòng $roomNumber', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 3),
                    Row(children: [
                      Text(monthStr, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                      if (daysOverdue > 0) ...[
                        const SizedBox(width: 6),
                        Text('Quá hạn $daysOverdue ngày', style: const TextStyle(fontSize: 10, color: Color(0xFFE11D48), fontWeight: FontWeight.w500)),
                      ],
                    ]),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${_fmt(debtAmount)}đ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFE11D48))),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: agingColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(agingLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: agingColor)),
                    ),
                  ]),
                ]),
              );
            }).toList()),
          ),
      ]),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────
  Widget _summaryCard(String label, String value, Color color, {IconData? icon}) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFF1F5F9)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (icon != null) ...[Icon(icon, size: 18, color: color.withValues(alpha: 0.7)), const SizedBox(height: 8)],
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
      ]),
    ),
  );

  Widget _legendDot(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 6),
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
  ]);

  Widget _buildNoData(String msg) => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), shape: BoxShape.circle), child: const Icon(Icons.bar_chart_rounded, size: 32, color: AppColors.primary)),
      const SizedBox(height: 14),
      Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
    ]),
  ));
}
