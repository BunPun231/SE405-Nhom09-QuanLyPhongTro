import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/meter_reading_service.dart';
import 'meter_widgets.dart';

/// Lựa chọn phòng cho bộ lọc lịch sử.
class MeterRoomOption {
  final int id;
  final String label;

  /// Mô tả phụ (vd. tên khách thuê) để lọc theo khách.
  final String? subtitle;
  const MeterRoomOption({required this.id, required this.label, this.subtitle});
}

/// UC72: lịch sử chỉ số đã duyệt theo tháng + biểu đồ tiêu thụ tương tác.
/// Quản lý: chọn phòng. Khách thuê: chỉ phòng của mình (một lựa chọn, ẩn bộ lọc).
class MeterHistoryView extends StatefulWidget {
  final List<MeterRoomOption> rooms;
  final int? initialRoomId;
  const MeterHistoryView({super.key, required this.rooms, this.initialRoomId});

  @override
  State<MeterHistoryView> createState() => _MeterHistoryViewState();
}

class _MeterHistoryViewState extends State<MeterHistoryView> with AutomaticKeepAliveClientMixin {
  int? _roomId;
  int? _serviceId;
  List<MeterReading> _history = [];
  bool _loading = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _roomId = widget.initialRoomId ?? (widget.rooms.isNotEmpty ? widget.rooms.first.id : null);
    _load();
  }

  @override
  void didUpdateWidget(covariant MeterHistoryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ids = widget.rooms.map((r) => r.id).toSet();
    if (_roomId == null || !ids.contains(_roomId)) {
      _roomId = widget.initialRoomId ?? (widget.rooms.isNotEmpty ? widget.rooms.first.id : null);
      _load();
    }
  }

  Future<void> _load() async {
    final roomId = _roomId;
    if (roomId == null) {
      setState(() => _history = []);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final h = await MeterReadingApi.history(roomId);
      if (!mounted || roomId != _roomId) return;
      final services = h.map((r) => r.serviceId).toSet();
      setState(() {
        _history = h;
        _loading = false;
        if (_serviceId == null || !services.contains(_serviceId)) {
          _serviceId = _defaultService(h);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = meterErrorText(e);
      });
    }
  }

  int? _defaultService(List<MeterReading> h) {
    if (h.isEmpty) return null;
    final electric = h.where((r) => MeterRules.isElectric(r.serviceName));
    return (electric.isNotEmpty ? electric.first : h.first).serviceId;
  }

  Map<int, String> get _services {
    final m = <int, String>{};
    for (final r in _history) {
      m.putIfAbsent(r.serviceId, () => r.serviceName.isEmpty ? 'Dịch vụ #${r.serviceId}' : r.serviceName);
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final rows = _history.where((r) => _serviceId == null || r.serviceId == _serviceId).toList();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (widget.rooms.length > 1) ...[
            _buildRoomFilter(),
            const SizedBox(height: 12),
          ],
          if (_services.length > 1) ...[
            _buildServiceChips(),
            const SizedBox(height: 12),
          ],
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_error != null)
            MeterEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Không tải được lịch sử',
              message: _error,
              actionLabel: 'Thử lại',
              onAction: _load,
            )
          else if (_roomId == null)
            const MeterEmptyState(icon: Icons.meeting_room_outlined, title: 'Chưa có phòng để xem lịch sử')
          else if (rows.isEmpty)
            const MeterEmptyState(
              icon: Icons.history_rounded,
              title: 'Chưa có chỉ số đã duyệt',
              message: 'Lịch sử chỉ hiển thị các kỳ đã được Quản lý duyệt.',
            )
          else ...[
            _buildChartCard(rows),
            const SizedBox(height: 16),
            Text('${rows.length} kỳ đã duyệt · mới nhất trước',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...rows.map(_buildRow),
          ],
        ],
      ),
    );
  }

  Widget _buildRoomFilter() {
    return DropdownButtonFormField<int>(
      initialValue: _roomId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Phòng / khách thuê',
        prefixIcon: const Icon(Icons.meeting_room_outlined, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      items: widget.rooms
          .map((r) => DropdownMenuItem(
                value: r.id,
                child: Text(
                  r.subtitle == null ? 'Phòng ${r.label}' : 'Phòng ${r.label} · ${r.subtitle}',
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: (v) {
        if (v == null || v == _roomId) return;
        setState(() => _roomId = v);
        _load();
      },
    );
  }

  Widget _buildServiceChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _services.entries.map((e) {
        final selected = e.key == _serviceId;
        return ChoiceChip(
          label: Text(e.value),
          selected: selected,
          showCheckmark: true,
          checkmarkColor: Colors.white,
          materialTapTargetSize: MaterialTapTargetSize.padded,
          avatar: selected
              ? null
              : Icon(MeterRules.isElectric(e.value) ? Icons.bolt_rounded : Icons.water_drop_rounded,
                  size: 16, color: AppColors.textSecondaryLight),
          selectedColor: AppColors.primary,
          backgroundColor: Colors.white,
          side: BorderSide(color: selected ? AppColors.primary : AppColors.borderLight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondaryLight,
          ),
          onSelected: (_) => setState(() => _serviceId = e.key),
        );
      }).toList(),
    );
  }

  Widget _buildChartCard(List<MeterReading> rows) {
    final points = MeterRules.buildTrend(rows);
    final avg = points.isEmpty ? 0.0 : points.fold<double>(0, (s, p) => s + p.consumption) / points.length;
    final maxY = points.fold<double>(0, (m, p) => p.consumption > m ? p.consumption : m);
    final top = maxY <= 0 ? 10.0 : maxY * 1.25;
    final serviceName = _services[_serviceId] ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MeterTone.mist),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tiêu thụ $serviceName',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MeterTone.heading)),
                      Text('${points.length} tháng gần nhất · chạm vào điểm để xem số',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                    ],
                  ),
                ),
                MeterNumber(label: 'Trung bình', value: MeterRules.formatReading(avg), fontSize: 16),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: points.length < 2
                ? Center(
                    child: Text(
                      points.isEmpty
                          ? 'Chưa đủ dữ liệu để vẽ biểu đồ'
                          : 'Cần ít nhất 2 kỳ để vẽ xu hướng (kỳ này: ${MeterRules.formatReading(points.first.consumption)})',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: top,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: top / 4,
                        getDrawingHorizontalLine: (_) => const FlLine(color: MeterTone.mist, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      extraLinesData: ExtraLinesData(horizontalLines: [
                        HorizontalLine(
                          y: avg,
                          color: AppColors.textSecondaryLight.withValues(alpha: 0.6),
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                      ]),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 44,
                            interval: top / 4,
                            getTitlesWidget: (v, meta) => SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(MeterRules.formatReading(v.roundToDouble()),
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 28,
                            getTitlesWidget: (v, meta) {
                              final i = v.round();
                              if (i < 0 || i >= points.length || v != i.toDouble()) return const SizedBox.shrink();
                              // Thưa nhãn khi nhiều tháng để không chồng chữ.
                              if (points.length > 6 && i.isOdd && i != points.length - 1) {
                                return const SizedBox.shrink();
                              }
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(MeterRules.shortMonthLabel(points[i].monthKey),
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                              );
                            },
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => AppColors.textPrimaryLight,
                          tooltipRoundedRadius: 10,
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          getTooltipItems: (spots) => spots.map((s) {
                            final p = points[s.x.round()];
                            return LineTooltipItem(
                              '${MeterRules.monthLabel(p.monthKey)}\n',
                              const TextStyle(color: Colors.white, fontSize: 12),
                              children: [
                                TextSpan(
                                  text: MeterRules.formatReading(p.consumption),
                                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                                if (p.meterReset)
                                  const TextSpan(
                                      text: '\nThay đồng hồ', style: TextStyle(color: Colors.white, fontSize: 11)),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].consumption),
                          ],
                          isCurved: true,
                          preventCurveOverShooting: true,
                          color: AppColors.primary,
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, _, __, ___) {
                              final high = MeterRules.isHighConsumption(spot.y, avg);
                              return FlDotCirclePainter(
                                radius: 4,
                                color: high ? AppColors.danger : AppColors.primary,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.08)),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(MeterReading r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MeterTone.mist),
      ),
      child: Row(
        children: [
          MeterImageThumb(url: r.imageUrl, size: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(MeterRules.monthLabel(r.monthKey),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MeterTone.heading)),
                    ),
                    if (r.isMeterReset)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Thay đồng hồ',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: MeterTone.warningText)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${MeterRules.formatReading(r.oldReading)} → ${MeterRules.formatReading(r.newReading)}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Tiêu thụ', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
              Text(MeterRules.formatReading(r.consumption),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }
}
