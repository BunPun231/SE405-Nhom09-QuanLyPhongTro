import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/invoice_service.dart';
import 'invoice_widgets.dart';

/// UC78 (thủ công): Quản lý ghi nhận khoản tiền mặt / chuyển khoản đã thu cho một hóa đơn.
/// Trả về true khi ghi nhận thành công.
Future<bool?> showManualPaymentSheet(BuildContext context, InvoiceResult invoice) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ManualPaymentSheet(invoice: invoice),
  );
}

class _ManualPaymentSheet extends StatefulWidget {
  final InvoiceResult invoice;
  const _ManualPaymentSheet({required this.invoice});

  @override
  State<_ManualPaymentSheet> createState() => _ManualPaymentSheetState();
}

class _ManualPaymentSheetState extends State<_ManualPaymentSheet> {
  late final TextEditingController _amountCtrl;
  String _method = 'CASH';
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: formatVnd(widget.invoice.remainingAmount, withSymbol: false));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  double get _amount => parseVndInput(_amountCtrl.text) ?? 0;

  Future<void> _submit() async {
    final amount = _amount;
    if (amount <= 0) {
      setState(() => _error = 'Số tiền phải lớn hơn 0.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await PaymentService.recordManual(invoiceId: widget.invoice.id, amount: amount, paymentMethod: _method);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = cleanError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    return SheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(
            icon: Icons.payments_rounded,
            iconColor: InvoiceTones.confirm,
            title: 'Ghi nhận đã thu',
            subtitle: '${inv.roomLabel} · ${formatBillingMonth(inv.billingMonth)} · HĐ #${inv.id}',
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InvoiceAmountTriple(
                    total: inv.totalAmount,
                    paid: inv.paidAmount,
                    remaining: inv.remainingAmount,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    decoration: invoiceInputDecoration('Số tiền đã thu', suffixText: 'đ'),
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  const SizedBox(height: 16),
                  const SectionLabel('Phương thức'),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'CASH', label: Text('Tiền mặt'), icon: Icon(Icons.payments_outlined)),
                      ButtonSegment(
                          value: 'BANK_TRANSFER', label: Text('Chuyển khoản'), icon: Icon(Icons.account_balance_outlined)),
                    ],
                    selected: {_method},
                    onSelectionChanged: (s) => setState(() => _method = s.first),
                    style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(48, 48))),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: InvoiceTones.paper,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: InvoiceTones.hairline),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 18, color: InvoiceTones.muted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            describePaymentOutcome(_amount, inv.remainingAmount),
                            style: const TextStyle(fontSize: 13, color: InvoiceTones.heading),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(fontSize: 13, color: InvoiceTones.dangerText)),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: InvoiceButtonStyles.confirm(),
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_rounded),
                    label: Text(_saving ? 'Đang ghi nhận...' : 'Xác nhận đã thu ${formatVnd(_amount)}'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
