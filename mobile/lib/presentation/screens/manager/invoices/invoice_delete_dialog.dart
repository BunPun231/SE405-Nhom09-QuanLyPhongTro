import 'package:flutter/material.dart';

import '../../../../core/services/invoice_service.dart';
import 'invoice_widgets.dart';

/// UC77: Xác nhận xóa hóa đơn PENDING chưa có thanh toán, bắt buộc nhập lý do.
/// Trả về true khi đã xóa.
Future<bool?> showDeleteInvoiceDialog(BuildContext context, InvoiceResult invoice) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _DeleteInvoiceDialog(invoice: invoice),
  );
}

class _DeleteInvoiceDialog extends StatefulWidget {
  final InvoiceResult invoice;
  const _DeleteInvoiceDialog({required this.invoice});

  @override
  State<_DeleteInvoiceDialog> createState() => _DeleteInvoiceDialogState();
}

class _DeleteInvoiceDialogState extends State<_DeleteInvoiceDialog> {
  final _reasonCtrl = TextEditingController();
  bool _deleting = false;
  String? _error;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final reason = _reasonCtrl.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = 'Vui lòng nhập lý do xóa.');
      return;
    }
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await InvoiceService.delete(widget.invoice.id, reason: reason);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _deleting = false;
          _error = cleanError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    return AlertDialog(
      icon: const Icon(Icons.delete_forever_rounded, color: InvoiceTones.dangerText, size: 32),
      title: Text('Xóa hóa đơn #${inv.id}?', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${inv.roomLabel} · ${formatBillingMonth(inv.billingMonth)} · ${formatVnd(inv.totalAmount)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: InvoiceTones.heading),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hóa đơn sẽ bị ẩn khỏi danh sách. Chỉ số điện nước vẫn được giữ để tạo lại hóa đơn kỳ này.',
              style: TextStyle(fontSize: 13, color: InvoiceTones.muted, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonCtrl,
              autofocus: true,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: invoiceInputDecoration('Lý do xóa (bắt buộc)', hint: 'VD: Tạo nhầm phòng'),
              onChanged: (_) => setState(() => _error = null),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(fontSize: 13, color: InvoiceTones.dangerText)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _deleting ? null : () => Navigator.pop(context, false),
          child: const Text('Giữ lại'),
        ),
        ElevatedButton(
          style: InvoiceButtonStyles.danger(),
          onPressed: _deleting || _reasonCtrl.text.trim().isEmpty ? null : _delete,
          child: Text(_deleting ? 'Đang xóa...' : 'Xóa hóa đơn'),
        ),
      ],
    );
  }
}
