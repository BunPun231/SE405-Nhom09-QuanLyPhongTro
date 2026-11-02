import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/invoice_service.dart';
import 'invoice_widgets.dart';

/// UC76: Hủy hóa đơn PENDING bị sai và tái cấp hóa đơn mới với số liệu đã hiệu chỉnh.
/// Trả về hóa đơn MỚI khi thành công.
Future<InvoiceResult?> showInvoiceAdjustSheet(BuildContext context, InvoiceResult invoice) {
  return showModalBottomSheet<InvoiceResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _InvoiceAdjustSheet(invoice: invoice),
  );
}

class _AdjustmentRow {
  bool surcharge;
  final TextEditingController description = TextEditingController();
  final TextEditingController amount = TextEditingController();

  _AdjustmentRow() : surcharge = true;

  InvoiceAdjustmentItem toItem() {
    final v = (parseVndInput(amount.text) ?? 0).abs();
    return InvoiceAdjustmentItem(description: description.text, amount: surcharge ? v : -v);
  }

  void dispose() {
    description.dispose();
    amount.dispose();
  }
}

class _InvoiceAdjustSheet extends StatefulWidget {
  final InvoiceResult invoice;
  const _InvoiceAdjustSheet({required this.invoice});

  @override
  State<_InvoiceAdjustSheet> createState() => _InvoiceAdjustSheetState();
}

class _InvoiceAdjustSheetState extends State<_InvoiceAdjustSheet> {
  late final List<InvoiceLine> _lines;
  final Map<int, TextEditingController> _readingCtrls = {}; // serviceId → chỉ số mới
  final Map<int, InvoiceLine> _meterLines = {}; // serviceId → dòng đầu tiên
  final Map<int, TextEditingController> _amountCtrls = {}; // detailId → số tiền
  final List<_AdjustmentRow> _rows = [];
  final _reasonCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _lines = buildInvoiceLines(widget.invoice);
    for (final l in _lines) {
      if (l.isMeter && l.serviceId != 0) {
        if (!_meterLines.containsKey(l.serviceId)) {
          _meterLines[l.serviceId] = l;
          _readingCtrls[l.serviceId] = TextEditingController(text: l.newReading!.toStringAsFixed(0));
        }
      } else if (!l.isAdjustment && l.detailId > 0) {
        _amountCtrls[l.detailId] = TextEditingController(text: formatVnd(l.amount, withSymbol: false));
      }
    }
  }

  @override
  void dispose() {
    for (final c in _readingCtrls.values) {
      c.dispose();
    }
    for (final c in _amountCtrls.values) {
      c.dispose();
    }
    for (final r in _rows) {
      r.dispose();
    }
    _reasonCtrl.dispose();
    super.dispose();
  }

  Map<int, double> get _correctedReadings {
    final out = <int, double>{};
    _readingCtrls.forEach((serviceId, ctrl) {
      final v = double.tryParse(ctrl.text.trim().replaceAll(',', '.'));
      final original = _meterLines[serviceId]!.newReading!;
      if (v != null && v != original) out[serviceId] = v;
    });
    return out;
  }

  Map<int, double> get _editedAmounts {
    final out = <int, double>{};
    _amountCtrls.forEach((detailId, ctrl) {
      final v = parseVndInput(ctrl.text);
      final original = _lines.firstWhere((l) => l.detailId == detailId).amount;
      if (v != null && v.round() != original.round()) out[detailId] = v;
    });
    return out;
  }

  InvoiceAdjustmentCalculator get _calc => InvoiceAdjustmentCalculator(
        lines: _lines,
        editedAmounts: _editedAmounts,
        correctedReadings: _correctedReadings,
        adjustments: _rows.map((r) => r.toItem()).toList(),
      );

  Future<void> _submit() async {
    final calc = _calc;
    final err = calc.validate(_reasonCtrl.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    if (!calc.hasChanges) {
      setState(() => _error = 'Chưa có thay đổi nào. Hãy sửa chỉ số, số tiền hoặc thêm khoản phụ thu/giảm trừ.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận tái cấp?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: Text(
          'Hóa đơn #${widget.invoice.id} sẽ chuyển sang Đã hủy và một hóa đơn mới '
          '${calc.isApproximate ? 'khoảng ' : ''}${formatVnd(calc.newTotal)} được tạo. '
          'Khách thuê sẽ nhận thông báo.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Xem lại')),
          ElevatedButton(
            style: InvoiceButtonStyles.primary(),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy & tái cấp'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final reissued = await InvoiceService.adjust(
        widget.invoice.id,
        reason: _reasonCtrl.text,
        correctedReadings: calc.correctedReadings,
        editedAmounts: calc.editedAmounts,
        adjustments: calc.adjustments,
      );
      if (mounted) Navigator.pop(context, reissued);
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
    final calc = _calc;
    return SheetFrame(
      maxHeightFactor: 0.95,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(
            icon: Icons.edit_note_rounded,
            title: 'Hủy & tái cấp hóa đơn',
            subtitle: '${inv.roomLabel} · ${formatBillingMonth(inv.billingMonth)} · HĐ #${inv.id}',
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_meterLines.isNotEmpty) ...[
                    const SectionLabel('Chỉ số điện nước đúng'),
                    for (final entry in _meterLines.entries) _readingField(entry.key, entry.value),
                    const SizedBox(height: 8),
                  ],
                  if (_amountCtrls.isNotEmpty) ...[
                    const SectionLabel('Sửa số tiền từng khoản'),
                    for (final l in _lines.where((l) => _amountCtrls.containsKey(l.detailId))) _amountField(l),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      const Expanded(child: SectionLabel('Phụ thu / Giảm trừ')),
                      TextButton.icon(
                        onPressed: () => setState(() => _rows.add(_AdjustmentRow())),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Thêm khoản'),
                      ),
                    ],
                  ),
                  if (_rows.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Chưa có khoản phụ thu hay giảm trừ.',
                          style: TextStyle(fontSize: 13, color: InvoiceTones.muted)),
                    ),
                  for (var i = 0; i < _rows.length; i++) _adjustmentRow(i),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reasonCtrl,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: invoiceInputDecoration('Lý do hủy và tái cấp (bắt buộc)',
                        hint: 'VD: Nhập sai chỉ số điện, giảm giá tháng Tết'),
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  const SizedBox(height: 16),
                  _preview(calc),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(fontSize: 13, color: InvoiceTones.dangerText)),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: InvoiceButtonStyles.primary(),
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.autorenew_rounded),
                    label: Text(_saving ? 'Đang tái cấp...' : 'Xác nhận tái cấp'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readingField(int serviceId, InvoiceLine line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.name.replaceAll(RegExp(r'\s*\(?bậc.*$', caseSensitive: false), ''),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: InvoiceTones.heading)),
                Text(
                  'Cũ ${line.oldReading!.toStringAsFixed(0)} · đã tính ${line.newReading!.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, color: InvoiceTones.muted),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 130,
            child: TextField(
              controller: _readingCtrls[serviceId],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              decoration: invoiceInputDecoration('Chỉ số mới'),
              onChanged: (_) => setState(() => _error = null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountField(InvoiceLine line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: InvoiceTones.heading)),
                Text('Hiện tại ${formatVnd(line.amount)}', style: const TextStyle(fontSize: 12, color: InvoiceTones.muted)),
              ],
            ),
          ),
          SizedBox(
            width: 150,
            child: TextField(
              controller: _amountCtrls[line.detailId],
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              decoration: invoiceInputDecoration('Số tiền', suffixText: 'đ'),
              onChanged: (_) => setState(() => _error = null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adjustmentRow(int index) {
    final row = _rows[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      decoration: BoxDecoration(
        color: InvoiceTones.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: InvoiceTones.hairline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Phụ thu')),
                    ButtonSegment(value: false, label: Text('Giảm trừ')),
                  ],
                  selected: {row.surcharge},
                  onSelectionChanged: (s) => setState(() => row.surcharge = s.first),
                  style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(48, 48))),
                ),
              ),
              IconButton(
                tooltip: 'Bỏ khoản này',
                onPressed: () => setState(() => _rows.removeAt(index).dispose()),
                icon: const Icon(Icons.delete_outline_rounded, color: InvoiceTones.dangerText),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: row.description,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: invoiceInputDecoration('Lý do / mô tả', hint: row.surcharge ? 'VD: Sửa khóa' : 'VD: Giảm giá'),
                    onChanged: (_) => setState(() => _error = null),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 130,
                  child: TextField(
                    controller: row.amount,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    decoration: invoiceInputDecoration('Số tiền', suffixText: 'đ'),
                    onChanged: (_) => setState(() => _error = null),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _preview(InvoiceAdjustmentCalculator calc) {
    final diff = calc.difference;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _previewRow('Tổng hóa đơn cũ', formatVnd(calc.originalTotal)),
          const SizedBox(height: 6),
          _previewRow(
            diff >= 0 ? 'Tăng thêm' : 'Giảm bớt',
            formatVnd(diff.abs()),
            color: diff > 0 ? InvoiceTones.dangerText : (diff < 0 ? InvoiceTones.paidText : InvoiceTones.heading),
          ),
          const Divider(height: 18),
          _previewRow(
            calc.isApproximate ? 'Tổng mới (ước tính)' : 'Tổng hóa đơn mới',
            formatVnd(calc.newTotal),
            bold: true,
          ),
          if (calc.isApproximate)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Giá bậc thang sẽ được máy chủ tính lại chính xác.',
                  style: TextStyle(fontSize: 12, color: InvoiceTones.muted)),
            ),
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value, {bool bold = false, Color? color}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: InvoiceTones.muted)),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 18 : 14,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
              color: color ?? InvoiceTones.ink,
            ),
          ),
        ],
      );
}
