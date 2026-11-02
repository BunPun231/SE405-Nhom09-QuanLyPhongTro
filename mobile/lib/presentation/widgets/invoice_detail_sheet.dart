import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/invoice_service.dart';
import '../screens/manager/invoices/invoice_adjust_sheet.dart';
import '../screens/manager/invoices/invoice_delete_dialog.dart';
import '../screens/manager/invoices/invoice_widgets.dart';
import '../screens/manager/invoices/manual_payment_sheet.dart';
import 'viet_qr_payment_sheet.dart';

/// UC75: Chi tiết hóa đơn — bảng kê từng khoản, chỉ số điện nước đã dùng, lịch sử thanh toán
/// và VietQR khi chưa thanh toán xong. Với Quản lý ([isManager]) có thêm: ghi nhận đã thu (UC78),
/// hủy & tái cấp (UC76), xóa (UC77).
class InvoiceDetailSheet extends StatefulWidget {
  final int invoiceId;
  final InvoiceResult? initialInvoice;
  final VoidCallback? onPaymentSuccess;
  final bool isManager;

  /// Gọi khi hóa đơn thay đổi (thu tiền, tái cấp, xóa) để màn hình gốc tải lại.
  final VoidCallback? onChanged;

  const InvoiceDetailSheet({
    super.key,
    required this.invoiceId,
    this.initialInvoice,
    this.onPaymentSuccess,
    this.isManager = false,
    this.onChanged,
  });

  static void show(
    BuildContext context, {
    required int invoiceId,
    InvoiceResult? initialInvoice,
    VoidCallback? onPaymentSuccess,
    bool isManager = false,
    VoidCallback? onChanged,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InvoiceDetailSheet(
        invoiceId: invoiceId,
        initialInvoice: initialInvoice,
        onPaymentSuccess: onPaymentSuccess,
        isManager: isManager,
        onChanged: onChanged,
      ),
    );
  }

  @override
  State<InvoiceDetailSheet> createState() => _InvoiceDetailSheetState();
}

class _InvoiceDetailSheetState extends State<InvoiceDetailSheet> {
  late int _invoiceId;
  InvoiceResult? _invoice;
  List<TransactionResult> _payments = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _invoiceId = widget.invoiceId;
    _invoice = widget.initialInvoice;
    _fetchDetail();
  }

  void _notifyChanged() {
    widget.onChanged?.call();
    widget.onPaymentSuccess?.call();
  }

  Future<void> _fetchDetail() async {
    if (_invoice == null) setState(() => _isLoading = true);
    try {
      final res = await InvoiceService.get(_invoiceId);
      if (!mounted) return;
      setState(() {
        _invoice = res;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = cleanError(e);
          _isLoading = false;
        });
      }
    }
    try {
      final tx = await PaymentService.transactions(invoiceId: _invoiceId, size: 20);
      if (mounted) setState(() => _payments = tx.content);
    } catch (_) {
      // Lịch sử thanh toán là phần phụ; lỗi không chặn xem hóa đơn.
    }
  }

  void _copySummary(InvoiceResult inv, List<InvoiceLine> lines) {
    final sb = StringBuffer()
      ..writeln('HÓA ĐƠN #${inv.id} - ${inv.roomLabel}')
      ..writeln('Kỳ: ${formatBillingMonth(inv.billingMonth)} · Hạn: ${formatDateVi(inv.dueDate)}')
      ..writeln('Trạng thái: ${invoiceStatusLabel(inv.status)}');
    for (final l in lines) {
      sb.writeln('• ${l.name}: ${formatVnd(l.amount)}');
    }
    sb
      ..writeln('Tổng cộng: ${formatVnd(inv.totalAmount)}')
      ..writeln('Đã thanh toán: ${formatVnd(inv.paidAmount)}')
      ..writeln('Còn lại: ${formatVnd(inv.remainingAmount)}');
    Clipboard.setData(ClipboardData(text: sb.toString()));
    showInvoiceSnack(context, 'Đã sao chép tóm tắt hóa đơn.');
  }

  Future<void> _recordPayment(InvoiceResult inv) async {
    final ok = await showManualPaymentSheet(context, inv);
    if (ok == true && mounted) {
      showInvoiceSnack(context, 'Đã ghi nhận thanh toán cho hóa đơn #${inv.id}.');
      _notifyChanged();
      _fetchDetail();
    }
  }

  Future<void> _adjust(InvoiceResult inv) async {
    final reissued = await showInvoiceAdjustSheet(context, inv);
    if (reissued != null && mounted) {
      showInvoiceSnack(context, 'Đã hủy HĐ #${inv.id} và tái cấp HĐ #${reissued.id}.');
      setState(() {
        _invoiceId = reissued.id;
        _invoice = reissued;
        _payments = [];
      });
      _notifyChanged();
    }
  }

  Future<void> _delete(InvoiceResult inv) async {
    final ok = await showDeleteInvoiceDialog(context, inv);
    if (ok == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(
        content: Text('Đã xóa hóa đơn #${inv.id}.'),
        behavior: SnackBarBehavior.floating,
      ));
      _notifyChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = _invoice;
    return SheetFrame(
      maxHeightFactor: 0.94,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(
            icon: Icons.receipt_long_rounded,
            title: 'Hóa đơn #$_invoiceId',
            subtitle: inv != null ? '${inv.roomLabel} · ${formatBillingMonth(inv.billingMonth)}' : 'Đang tải...',
          ),
          Flexible(
            child: _isLoading && inv == null
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
                  )
                : _error != null && inv == null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 40, color: InvoiceTones.dangerText),
                            const SizedBox(height: 10),
                            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              style: InvoiceButtonStyles.outlined(),
                              onPressed: _fetchDetail,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : inv == null
                        ? const SizedBox.shrink()
                        : RefreshIndicator(
                            onRefresh: _fetchDetail,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                              child: _content(inv),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _content(InvoiceResult inv) {
    final lines = buildInvoiceLines(inv);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _headerCard(inv),
        const SizedBox(height: 20),
        const SectionLabel('Bảng kê các khoản'),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: InvoiceTones.hairline),
          ),
          child: Column(
            children: [
              if (lines.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Hóa đơn chưa có dòng chi tiết.', style: TextStyle(fontSize: 13, color: InvoiceTones.muted)),
                ),
              for (var i = 0; i < lines.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: InvoiceTones.mist),
                _lineTile(lines[i]),
              ],
              const Divider(height: 1, color: InvoiceTones.hairline),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _sumRow('Tổng cộng hóa đơn', formatVnd(inv.totalAmount), bold: true),
                    if (inv.balanceDeduction > 0) ...[
                      const SizedBox(height: 8),
                      _sumRow('Khấu trừ từ số dư', '-${formatVnd(inv.balanceDeduction)}', color: InvoiceTones.paidText),
                    ],
                    const SizedBox(height: 8),
                    _sumRow('Đã thanh toán', formatVnd(inv.paidAmount), color: InvoiceTones.paidText),
                    const SizedBox(height: 8),
                    _sumRow(
                      'Còn phải đóng',
                      formatVnd(inv.remainingAmount),
                      bold: true,
                      color: inv.remainingAmount > 0 && !inv.isVoid ? InvoiceTones.dangerText : InvoiceTones.paidText,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_payments.isNotEmpty) ...[
          const SizedBox(height: 20),
          const SectionLabel('Các lần thanh toán'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: InvoiceTones.hairline),
            ),
            child: Column(
              children: [
                for (final p in _payments)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(formatDateVi(p.paidAt, withTime: true),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: InvoiceTones.heading)),
                              Text('${paymentMethodLabel(p.paymentMethod)} · ${p.transactionRef ?? ''}',
                                  style: const TextStyle(fontSize: 12, color: InvoiceTones.muted),
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        Text(formatVnd(p.amount),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: InvoiceTones.paidText)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (inv.isUnpaid && inv.remainingAmount > 0) ...[
          const SizedBox(height: 20),
          const SectionLabel('Thanh toán VietQR'),
          VietQrInlinePanel(key: ValueKey('qr-${inv.id}-${inv.remainingAmount}'), invoiceId: inv.id),
          if (!widget.isManager) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: InvoiceButtonStyles.confirm(),
              onPressed: () {
                Navigator.pop(context);
                VietQrPaymentSheet.show(context, invoiceId: inv.id, onSuccess: widget.onPaymentSuccess ?? widget.onChanged);
              },
              icon: const Icon(Icons.qr_code_2_rounded),
              label: const Text('Thanh toán VietQR'),
            ),
          ],
        ],
        if (widget.isManager) ..._managerActions(inv),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: InvoiceButtonStyles.outlined(),
          onPressed: () => _copySummary(inv, lines),
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text('Sao chép tóm tắt'),
        ),
      ],
    );
  }

  List<Widget> _managerActions(InvoiceResult inv) {
    if (inv.isVoid) return const [];
    return [
      const SizedBox(height: 20),
      const SectionLabel('Thao tác'),
      if (inv.isUnpaid)
        ElevatedButton.icon(
          style: InvoiceButtonStyles.confirm(),
          onPressed: () => _recordPayment(inv),
          icon: const Icon(Icons.payments_rounded),
          label: const Text('Ghi nhận đã thu'),
        ),
      if (inv.canAdjust) ...[
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: InvoiceButtonStyles.outlined(foreground: AppColors.primary),
                onPressed: () => _adjust(inv),
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Hủy & tái cấp'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: InvoiceButtonStyles.outlined(foreground: InvoiceTones.dangerText),
                onPressed: () => _delete(inv),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Xóa'),
              ),
            ),
          ],
        ),
      ] else if (inv.status == 'PARTIAL' || inv.status == 'PAID')
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: InvoiceTones.paper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: InvoiceTones.hairline),
          ),
          child: const Text(
            'Không thể hủy hoặc xóa hóa đơn đã có giao dịch. Vui lòng khấu trừ vào kỳ sau.',
            style: TextStyle(fontSize: 13, color: InvoiceTones.heading),
          ),
        ),
    ];
  }

  Widget _headerCard(InvoiceResult inv) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: InvoiceTones.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: InvoiceTones.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(inv.roomLabel,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: InvoiceTones.heading)),
              ),
              InvoiceStatusBadge(inv.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _meta('Kỳ hóa đơn', formatBillingMonth(inv.billingMonth))),
              Expanded(child: _meta('Hạn thanh toán', formatDateVi(inv.dueDate))),
            ],
          ),
          if (inv.replacesInvoiceId != null) ...[
            const SizedBox(height: 10),
            Text('Tái cấp thay cho hóa đơn #${inv.replacesInvoiceId}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
          ],
          if (inv.cancelReason != null && inv.cancelReason!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Lý do hủy: ${inv.cancelReason}',
                  style: const TextStyle(fontSize: 13, color: InvoiceTones.dangerText)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _meta(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: InvoiceTones.muted)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: InvoiceTones.heading)),
        ],
      );

  Widget _lineTile(InvoiceLine l) {
    final sub = <String>[];
    if (l.isMeter) {
      sub.add('Chỉ số ${l.oldReading!.toStringAsFixed(0)} → ${l.newReading!.toStringAsFixed(0)}'
          ' · dùng ${l.consumption!.toStringAsFixed(0)} ${l.meterUnit}');
    }
    if (!l.isAdjustment && l.unitPrice > 0 && l.quantity != null && l.quantity! > 0) {
      final qty = l.quantity!;
      final qtyText = qty == qty.roundToDouble() ? qty.toStringAsFixed(0) : qty.toStringAsFixed(2);
      sub.add('$qtyText × ${formatVnd(l.unitPrice)}');
    }
    final amountColor = l.isAdjustment
        ? (l.amount < 0 ? InvoiceTones.paidText : InvoiceTones.dangerText)
        : InvoiceTones.heading;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: InvoiceTones.heading)),
                for (final s in sub)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(s, style: const TextStyle(fontSize: 12, color: InvoiceTones.muted)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(formatVnd(l.amount), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: amountColor)),
        ],
      ),
    );
  }

  Widget _sumRow(String label, String value, {bool bold = false, Color? color}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: bold ? InvoiceTones.heading : InvoiceTones.muted)),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 17 : 14,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
              color: color ?? InvoiceTones.ink,
            ),
          ),
        ],
      );
}
