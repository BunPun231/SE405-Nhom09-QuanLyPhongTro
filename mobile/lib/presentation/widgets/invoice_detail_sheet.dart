import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/invoice_service.dart';
import 'viet_qr_payment_sheet.dart';

String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );

String _fmtMonth(String? raw) {
  if (raw == null || raw.isEmpty) return '-';
  try {
    final d = DateTime.parse(raw);
    return 'Tháng ${d.month}/${d.year}';
  } catch (_) {
    return raw.length >= 7 ? raw.substring(0, 7) : raw;
  }
}

String _fmtDate(String? raw) {
  if (raw == null || raw.isEmpty) return 'Không có';
  try {
    final d = DateTime.parse(raw);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  } catch (_) {
    return raw;
  }
}

const Map<String, String> _chargeTypeLabels = {
  'FIXED': 'Cố định',
  'PER_PERSON': 'Theo người',
  'PER_INDEX': 'Theo chỉ số',
  'PER_QUANTITY': 'Theo số lượng',
  'METERED': 'Theo chỉ số',
  'TIERED': 'Lũy tiến bậc thang',
};

String _getChargeLabel(String chargeType, String serviceName) {
  if (chargeType.isNotEmpty && _chargeTypeLabels.containsKey(chargeType)) {
    return _chargeTypeLabels[chargeType]!;
  }
  final lower = serviceName.toLowerCase();
  if (lower.contains('phòng')) return 'Cố định (Tiền phòng)';
  if (lower.contains('điện')) return 'Theo chỉ số (Điện)';
  if (lower.contains('nước')) return 'Theo chỉ số (Nước)';
  if (lower.contains('người')) return 'Theo người';
  return 'Cố định';
}

class _FeeItem {
  final String serviceName;
  final String chargeType;
  final double? oldReading;
  final double? newReading;
  final double? consumption;
  final double unitPrice;
  final double totalCost;

  _FeeItem({
    required this.serviceName,
    required this.chargeType,
    this.oldReading,
    this.newReading,
    this.consumption,
    required this.unitPrice,
    required this.totalCost,
  });
}

double _calculateItemCost(Map<String, dynamic> item) {
  final basePrice = (item['basePrice'] as num?)?.toDouble() ?? 0;
  final chargeType = item['chargeType']?.toString() ?? '';
  if (chargeType == 'FIXED') return basePrice;
  if (chargeType == 'PER_PERSON') {
    final residents = (item['activeResidents'] as num?)?.toDouble() ?? 1;
    return basePrice * residents;
  }
  if (chargeType == 'PER_QUANTITY') {
    final qty = (item['quantity'] as num?)?.toDouble() ?? 1;
    return basePrice * qty;
  }
  if (chargeType == 'PER_INDEX' || chargeType == 'METERED') {
    final oldR = (item['oldReading'] as num?)?.toDouble() ?? 0;
    final newR = (item['newReading'] as num?)?.toDouble() ?? 0;
    final consumption = (newR - oldR).clamp(0, double.infinity).toDouble();
    final tiers = item['pricingTiers'] as List?;
    if (tiers != null && tiers.isNotEmpty) {
      double remaining = consumption;
      double totalCost = 0;
      for (final t in tiers) {
        if (remaining <= 0) break;
        if (t is Map<String, dynamic>) {
          final start = (t['tierStart'] as num?)?.toDouble() ?? 0;
          final end = (t['tierEnd'] as num?)?.toDouble();
          final price = (t['pricePerUnit'] as num?)?.toDouble() ?? 0;
          final double capacity = end != null ? (end - start) : remaining;
          final inTier = remaining < capacity ? remaining : capacity;
          if (inTier > 0) {
            totalCost += inTier * price;
            remaining -= inTier;
          }
        }
      }
      return totalCost;
    } else {
      return consumption * basePrice;
    }
  }
  return 0;
}

class InvoiceDetailSheet extends StatefulWidget {
  final int invoiceId;
  final InvoiceResult? initialInvoice;
  final VoidCallback? onPaymentSuccess;

  const InvoiceDetailSheet({
    super.key,
    required this.invoiceId,
    this.initialInvoice,
    this.onPaymentSuccess,
  });

  static void show(
    BuildContext context, {
    required int invoiceId,
    InvoiceResult? initialInvoice,
    VoidCallback? onPaymentSuccess,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InvoiceDetailSheet(
        invoiceId: invoiceId,
        initialInvoice: initialInvoice,
        onPaymentSuccess: onPaymentSuccess,
      ),
    );
  }

  @override
  State<InvoiceDetailSheet> createState() => _InvoiceDetailSheetState();
}

class _InvoiceDetailSheetState extends State<InvoiceDetailSheet> {
  InvoiceResult? _invoice;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _invoice = widget.initialInvoice;
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    if (_invoice == null) {
      setState(() => _isLoading = true);
    }
    try {
      final res = await InvoiceService.get(widget.invoiceId);
      if (mounted) {
        setState(() {
          _invoice = res;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  List<_FeeItem> _extractFeeItems(InvoiceResult inv, Map<String, dynamic>? snapshot) {
    final List<dynamic>? snapItems = snapshot?['items'] as List<dynamic>?;

    if (inv.details.isNotEmpty) {
      return inv.details.map((d) {
        Map<String, dynamic>? match;
        if (snapItems != null) {
          for (final item in snapItems) {
            if (item is Map<String, dynamic>) {
              final sId = item['serviceId'];
              final sName = (item['serviceName'] ?? '').toString().toLowerCase();
              if ((d.serviceId != 0 && sId == d.serviceId) ||
                  (d.serviceName.isNotEmpty && sName == d.serviceName.toLowerCase()) ||
                  (d.serviceName.isEmpty && sName.isNotEmpty)) {
                match = item;
                break;
              }
            }
          }
        }

        final name = d.serviceName.isNotEmpty
            ? d.serviceName
            : (match?['serviceName']?.toString() ?? 'Dịch vụ');

        final isMeter = name.toLowerCase().contains('điện') || name.toLowerCase().contains('nước');
        final cType = match?['chargeType']?.toString() ??
            (d.chargeType.isNotEmpty ? d.chargeType : (isMeter ? 'PER_INDEX' : 'FIXED'));

        final oldR = d.oldReading ?? (match?['oldReading'] as num?)?.toDouble();
        final newR = d.newReading ?? (match?['newReading'] as num?)?.toDouble();

        double? cons = d.consumption;
        if (cons == null && newR != null && oldR != null) {
          cons = (newR - oldR).clamp(0, double.infinity).toDouble();
        }
        cons ??= (match?['quantity'] as num?)?.toDouble() ??
            (match?['activeResidents'] as num?)?.toDouble();

        final uPrice = d.unitPrice > 0 ? d.unitPrice : ((match?['basePrice'] as num?)?.toDouble() ?? 0);
        double total = d.totalCost > 0 ? d.totalCost : (match != null ? _calculateItemCost(match) : 0);
        if (total == 0 && uPrice > 0) {
          if (cType == 'FIXED') {
            total = uPrice;
          } else if (cons != null && cons > 0) {
            total = cons * uPrice;
          }
        }

        return _FeeItem(
          serviceName: name,
          chargeType: cType,
          oldReading: oldR,
          newReading: newR,
          consumption: cons,
          unitPrice: uPrice,
          totalCost: total,
        );
      }).toList();
    }

    // Fallback if details is empty: construct from snapshot items
    if (snapItems != null && snapItems.isNotEmpty) {
      return snapItems.whereType<Map<String, dynamic>>().map((item) {
        final name = item['serviceName']?.toString() ?? 'Dịch vụ';
        final isMeter = name.toLowerCase().contains('điện') || name.toLowerCase().contains('nước');
        final cType = item['chargeType']?.toString() ?? (isMeter ? 'PER_INDEX' : 'FIXED');
        final oldR = (item['oldReading'] as num?)?.toDouble();
        final newR = (item['newReading'] as num?)?.toDouble();
        double? cons;
        if (cType == 'PER_INDEX' || cType == 'METERED') {
          if (newR != null && oldR != null) {
            cons = (newR - oldR).clamp(0, double.infinity).toDouble();
          }
        } else if (cType == 'PER_PERSON') {
          cons = (item['activeResidents'] as num?)?.toDouble();
        } else {
          cons = (item['quantity'] as num?)?.toDouble();
        }

        final uPrice = (item['basePrice'] as num?)?.toDouble() ?? 0;
        final total = _calculateItemCost(item);

        return _FeeItem(
          serviceName: name,
          chargeType: cType,
          oldReading: oldR,
          newReading: newR,
          consumption: cons,
          unitPrice: uPrice,
          totalCost: total,
        );
      }).toList();
    }

    return [];
  }

  void _copySummary(List<_FeeItem> feeItems) {
    if (_invoice == null) return;
    final inv = _invoice!;
    final sb = StringBuffer();
    sb.writeln('=== THÔNG TIN HÓA ĐƠN #${inv.id} ===');
    sb.writeln('Phòng: ${inv.roomNumber != null ? 'P.${inv.roomNumber}' : 'P.${inv.roomId}'}');
    sb.writeln('Kỳ thanh toán: ${_fmtMonth(inv.billingMonth)}');
    sb.writeln('Hạn nộp: ${_fmtDate(inv.dueDate)}');
    sb.writeln('Trạng thái: ${inv.status == 'PAID' ? 'Đã thanh toán' : inv.status == 'PARTIAL' ? 'Một phần' : 'Chưa thanh toán'}');
    sb.writeln('---------------------------');
    for (final d in feeItems) {
      sb.writeln('• ${d.serviceName}: ${_fmt(d.totalCost)}đ');
    }
    sb.writeln('---------------------------');
    sb.writeln('Tổng cộng: ${_fmt(inv.totalAmount)}đ');
    sb.writeln('Đã thu: ${_fmt(inv.paidAmount)}đ');
    sb.writeln('Còn nợ: ${_fmt(inv.totalAmount - inv.paidAmount)}đ');

    Clipboard.setData(ClipboardData(text: sb.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đã sao chép tóm tắt hóa đơn vào bộ nhớ tạm!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 14),

            // Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chi tiết hóa đơn #${widget.invoiceId}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                        ),
                        Text(
                          _invoice != null
                              ? '${_invoice!.roomNumber != null ? 'Phòng P.${_invoice!.roomNumber}' : 'Phòng ${_invoice!.roomId}'} · ${_fmtMonth(_invoice!.billingMonth)}'
                              : 'Đang tải thông tin...',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondaryLight),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            const Divider(height: 20, thickness: 1, color: Color(0xFFF1F5F9)),

            // Content
            Flexible(
              child: _isLoading && _invoice == null
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                      ),
                    )
                  : _error != null && _invoice == null
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.danger),
                              const SizedBox(height: 10),
                              Text('Lỗi: $_error', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _fetchDetail, child: const Text('Thử lại')),
                            ],
                          ),
                        )
                      : _invoice != null
                          ? SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              child: _buildInvoiceContent(_invoice!),
                            )
                          : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceContent(InvoiceResult inv) {
    final isPaid = inv.status == 'PAID';
    final isPending = inv.status == 'PENDING' || inv.status == 'PARTIAL';
    final remainingDebt = inv.totalAmount - inv.paidAmount;

    // Parse snapshot items if available
    Map<String, dynamic>? snapshot;
    if (inv.calculationSnapshot != null && inv.calculationSnapshot!.isNotEmpty) {
      try {
        snapshot = jsonDecode(inv.calculationSnapshot!) as Map<String, dynamic>;
      } catch (_) {}
    }

    final feeItems = _extractFeeItems(inv, snapshot);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Room & Status Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv.roomNumber != null ? 'Phòng P.${inv.roomNumber}' : 'Phòng ${inv.roomId}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 2),
                      Text('Mã hóa đơn: #${inv.id}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textSecondaryLight)),
                    ],
                  ),
                  _buildStatusBadge(inv.status),
                ],
              ),
              const Divider(height: 20, color: Color(0xFFE2E8F0)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _metaInfo('Kỳ hóa đơn', _fmtMonth(inv.billingMonth)),
                  _metaInfo('Hạn thanh toán', _fmtDate(inv.dueDate)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Section: Breakdown of fees (Chi tiết các khoản phí)
        const Text(
          'CHI TIẾT CÁC KHOẢN PHÍ',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight, letterSpacing: 0.5),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: feeItems.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('Không có chi tiết các khoản phí', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight))),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: feeItems.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (_, i) => _buildFeeItem(feeItems[i]),
                ),
        ),
        const SizedBox(height: 18),

        // Section: Breakdown Table (Bảng kê chi tiết các khoản tiền đóng góp)
        const Text(
          'BẢNG KÊ CHI TIẾT CÁC KHOẢN TIỀN ĐÓNG GÓP',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight, letterSpacing: 0.5),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              for (final f in feeItems) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(f.serviceName, style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w500)),
                      Text('${_fmt(f.totalCost)}đ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ],
              const Divider(height: 18, color: Color(0xFFE2E8F0)),
              _summaryRow('Tổng cộng hóa đơn', '${_fmt(inv.totalAmount)}đ', bold: true, color: const Color(0xFFDC2626), size: 15),
              const SizedBox(height: 6),
              _summaryRow('Đã thanh toán', '${_fmt(inv.paidAmount)}đ', color: const Color(0xFF059669)),
              const SizedBox(height: 6),
              _summaryRow('Còn lại cần thanh toán', '${_fmt(remainingDebt)}đ', bold: true, color: isPaid ? const Color(0xFF059669) : AppColors.danger, size: 13),
              if (inv.status == 'PARTIAL' && inv.totalAmount > 0) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (inv.paidAmount / inv.totalAmount).clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF059669)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tiến độ: ${(inv.paidAmount / inv.totalAmount * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                ),
              ],
            ],
          ),
        ),

        // Section: System Automatic Formulas if snapshot exists
        if (snapshot != null && snapshot['items'] is List && (snapshot['items'] as List).isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text(
            'CÔNG THỨC TÍNH CHI TIẾT (HỆ THỐNG TỰ ĐỘNG)',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight, letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in (snapshot['items'] as List))
                  _buildFormulaItem(item as Map<String, dynamic>),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Footer Actions
        if (isPending) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                VietQrPaymentSheet.show(
                  context,
                  invoiceId: inv.id,
                  onSuccess: widget.onPaymentSuccess,
                );
              },
              icon: const Icon(Icons.qr_code_2_rounded, size: 20),
              label: const Text('Thanh toán bằng VietQR ➜', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _copySummary(feeItems),
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Sao chép tóm tắt', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: const Text('Đóng', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metaInfo(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B))),
        ],
      );

  Widget _buildFeeItem(_FeeItem detail) {
    final chargeLabel = _getChargeLabel(detail.chargeType, detail.serviceName);
    final isMeter = detail.chargeType == 'PER_INDEX' ||
        detail.chargeType == 'METERED' ||
        detail.serviceName.toLowerCase().contains('điện') ||
        detail.serviceName.toLowerCase().contains('nước');
    final isWater = detail.serviceName.toLowerCase().contains('nước');
    final meterUnit = isWater ? 'khối' : 'số';

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.serviceName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'Loại: $chargeLabel',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                if (isMeter && detail.oldReading != null && detail.newReading != null) ...[
                  Text(
                    'Chỉ số: ${detail.oldReading!.toStringAsFixed(0)} → ${detail.newReading!.toStringAsFixed(0)} (dùng ${detail.consumption?.toStringAsFixed(0) ?? (detail.newReading! - detail.oldReading!).toStringAsFixed(0)} $meterUnit)',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                  ),
                ] else if (isMeter && detail.consumption != null && detail.consumption! > 0) ...[
                  Text(
                    'Tiêu thụ: ${detail.consumption!.toStringAsFixed(0)} $meterUnit',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                  ),
                ] else if (detail.chargeType == 'PER_PERSON' && detail.consumption != null) ...[
                  Text(
                    'Số người: ${detail.consumption!.toStringAsFixed(0)} người',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                  ),
                ] else if (detail.consumption != null && detail.consumption! > 1) ...[
                  Text(
                    'Số lượng: ${detail.consumption!.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                  ),
                ],
                if (detail.unitPrice > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Đơn giá: ${_fmt(detail.unitPrice)}đ${isMeter ? '/$meterUnit' : detail.chargeType == 'PER_PERSON' ? '/người' : ''}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${_fmt(detail.totalCost)}đ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false, Color? color, double size = 12}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: size, color: AppColors.textSecondaryLight)),
        Text(
          value,
          style: TextStyle(
            fontSize: size,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: color ?? const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildFormulaItem(Map<String, dynamic> item) {
    final serviceName = item['serviceName'] ?? 'Dịch vụ';
    final chargeType = item['chargeType'] ?? '';
    final basePrice = (item['basePrice'] as num?)?.toDouble() ?? 0;

    String explanation = '';
    if (chargeType == 'FIXED') {
      explanation = 'Phí cố định hàng tháng = ${_fmt(basePrice)} đ';
    } else if (chargeType == 'PER_PERSON') {
      final residents = item['activeResidents'] ?? 1;
      explanation = '${_fmt(basePrice)} đ/người × $residents người = ${_fmt(basePrice * (residents as num))} đ';
    } else if (chargeType == 'PER_QUANTITY') {
      final qty = item['quantity'] ?? 1;
      explanation = '${_fmt(basePrice)} đ × $qty đơn vị = ${_fmt(basePrice * (qty as num))} đ';
    } else if (chargeType == 'PER_INDEX' || chargeType == 'METERED') {
      final oldR = (item['oldReading'] as num?)?.toDouble() ?? 0;
      final newR = (item['newReading'] as num?)?.toDouble() ?? 0;
      final cons = (newR - oldR).clamp(0, double.infinity);
      final tiers = item['pricingTiers'] as List?;
      if (tiers != null && tiers.isNotEmpty) {
        explanation = 'Tiêu thụ: $newR - $oldR = ${cons.toStringAsFixed(0)} đơn vị (tính theo bậc thang)';
      } else {
        explanation = '($newR - $oldR) × ${_fmt(basePrice)} đ = ${_fmt(cons * basePrice)} đ';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(serviceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E293B))),
          const SizedBox(height: 2),
          Text(
            explanation,
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'PAID':
        color = const Color(0xFF059669);
        label = 'Đã thanh toán';
        break;
      case 'PARTIAL':
        color = const Color(0xFF0284C7);
        label = 'Một phần';
        break;
      case 'VOID':
      case 'CANCELLED':
        color = AppColors.danger;
        label = 'Đã hủy';
        break;
      default:
        color = const Color(0xFFD97706);
        label = 'Chưa thanh toán';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
