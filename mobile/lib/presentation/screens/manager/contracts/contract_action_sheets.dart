import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/contract_service.dart';
import '../../../../core/services/settlement_service.dart';
import 'contract_ui.dart';

Future<T?> _showSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SafeArea(top: false, child: child),
    ),
  );
}

Widget _sheetTitle(String title, String subtitle) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight)),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
      const SizedBox(height: 16),
    ],
  );
}

// ─── UC69: Ghi nhận thu cọc ────────────────────────────────────────────────

Future<bool> showDepositCollectSheet(BuildContext context, {required int contractId, required double depositAmount, required bool willActivate}) async {
  final ok = await _showSheet<bool>(
    context,
    _DepositCollectSheet(contractId: contractId, depositAmount: depositAmount, willActivate: willActivate),
  );
  return ok == true;
}

class _DepositCollectSheet extends StatefulWidget {
  final int contractId;
  final double depositAmount;
  final bool willActivate;
  const _DepositCollectSheet({required this.contractId, required this.depositAmount, required this.willActivate});

  @override
  State<_DepositCollectSheet> createState() => _DepositCollectSheetState();
}

class _DepositCollectSheetState extends State<_DepositCollectSheet> {
  DateTime _date = DateTime.now();
  String _method = 'CASH';
  final _note = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await ContractService.collectDeposit(
        widget.contractId,
        amount: widget.depositAmount,
        collectedDate: _date,
        paymentMethod: _method,
        note: _note.text,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, Fmt.errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sheetTitle('Ghi nhận thu tiền cọc', 'Xác nhận đã nhận tiền cọc của khách thuê.'),
          InfoRow(label: 'Số tiền cọc', value: Fmt.vnd(widget.depositAmount), emphasize: true),
          const SizedBox(height: 12),
          DateField(
            label: 'Ngày thu thực tế',
            value: _date,
            onTap: () async {
              final d = await pickDate(context, initial: _date, last: DateTime.now());
              if (d != null) setState(() => _date = d);
            },
          ),
          const SizedBox(height: 12),
          const Text('Phương thức', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'CASH', label: Text('Tiền mặt'), icon: Icon(Icons.payments_outlined)),
              ButtonSegment(value: 'BANK_TRANSFER', label: Text('Chuyển khoản'), icon: Icon(Icons.account_balance_outlined)),
            ],
            selected: {_method},
            onSelectionChanged: (s) => setState(() => _method = s.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: const InputDecoration(labelText: 'Ghi chú (tùy chọn)', hintText: 'VD: Mã giao dịch ngân hàng'),
          ),
          if (widget.willActivate) ...[
            const SizedBox(height: 12),
            const NoticeBox(
              text: 'Sau khi xác nhận, hợp đồng chuyển sang Đang hiệu lực và phòng chuyển sang Đang thuê.',
              tone: Tone.green,
              icon: Icons.verified_outlined,
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _saving ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: ContractTokens.confirmGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Xác nhận đã thu cọc'),
          ),
        ],
      ),
    );
  }
}

// ─── UC66: Điều chỉnh / gia hạn / phụ lục ─────────────────────────────────

Future<bool> showAdjustSheet(BuildContext context, {required ContractDetailResult contract}) async {
  final ok = await _showSheet<bool>(context, _AdjustSheet(contract: contract));
  return ok == true;
}

class _AdjustSheet extends StatefulWidget {
  final ContractDetailResult contract;
  const _AdjustSheet({required this.contract});

  @override
  State<_AdjustSheet> createState() => _AdjustSheetState();
}

class _AdjustSheetState extends State<_AdjustSheet> {
  String _type = 'RENEW';
  DateTime? _newEnd;
  DateTime? _effective;
  DateTime? _moveOut;
  final _price = TextEditingController();
  final _clause = TextEditingController();
  final _reason = TextEditingController();
  String? _error;
  bool _saving = false;

  DateTime? get _currentEnd => DateTime.tryParse(widget.contract.endDate);

  @override
  void initState() {
    super.initState();
    final end = _currentEnd;
    _newEnd = end == null ? null : ContractRules.addMonths(end, 6);
    _effective = DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _price.dispose();
    _clause.dispose();
    _reason.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_reason.text.trim().isEmpty) return 'Vui lòng nhập lý do điều chỉnh';
    switch (_type) {
      case 'RENEW':
        final end = _currentEnd;
        if (_newEnd == null) return 'Vui lòng chọn ngày kết thúc mới';
        if (end != null && !_newEnd!.isAfter(end)) return 'Ngày kết thúc mới phải sau ${Fmt.dateOf(end)}';
        return null;
      case 'PRICE_CHANGE':
        final p = Fmt.parseMoney(_price.text);
        if (p == null || p <= 0) return 'Giá thuê mới phải lớn hơn 0';
        if (_effective == null) return 'Vui lòng chọn ngày áp dụng';
        return null;
      case 'MANUAL_CLAUSE':
        if (_clause.text.trim().isEmpty) return 'Vui lòng nhập nội dung điều khoản';
        if (_effective == null) return 'Vui lòng chọn ngày hiệu lực';
        return null;
      case 'MOVE_OUT_NOTICE':
        if (_moveOut == null) return 'Vui lòng chọn ngày dự kiến trả phòng';
        final today = DateTime.now();
        if (_moveOut!.isBefore(DateTime(today.year, today.month, today.day))) {
          return 'Ngày trả phòng phải từ hôm nay trở đi';
        }
        return null;
    }
    return null;
  }

  Future<void> _submit() async {
    final err = _validate();
    setState(() => _error = err);
    if (err != null) return;
    setState(() => _saving = true);
    try {
      await ContractService.adjust(
        widget.contract.id,
        type: _type,
        reason: _reason.text.trim(),
        newEndDate: _type == 'RENEW' ? _newEnd : null,
        effectiveDate: _type == 'PRICE_CHANGE' || _type == 'MANUAL_CLAUSE' ? _effective : null,
        newRentPrice: _type == 'PRICE_CHANGE' ? Fmt.parseMoney(_price.text) : null,
        intendedMoveOutDate: _type == 'MOVE_OUT_NOTICE' ? _moveOut : null,
        clause: _type == 'MANUAL_CLAUSE' ? _clause.text.trim() : null,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = Fmt.errorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.contract;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sheetTitle('Điều chỉnh hợp đồng', 'Mọi thay đổi được lưu thành phụ lục kèm lý do.'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in const [
                ['RENEW', 'Gia hạn'],
                ['PRICE_CHANGE', 'Đổi giá thuê'],
                ['MANUAL_CLAUSE', 'Thêm điều khoản'],
                ['MOVE_OUT_NOTICE', 'Báo trả phòng'],
              ])
                ChoiceChip(
                  label: Text(t[1]),
                  selected: _type == t[0],
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onSelected: (_) => setState(() {
                    _type = t[0];
                    _error = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_type == 'RENEW') ...[
            InfoRow(label: 'Ngày kết thúc hiện tại', value: Fmt.date(c.endDate)),
            const SizedBox(height: 8),
            DateField(
              label: 'Ngày kết thúc mới',
              value: _newEnd,
              onTap: () async {
                final d = await pickDate(context, initial: _newEnd ?? _currentEnd, first: _currentEnd);
                if (d != null) setState(() => _newEnd = d);
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final m in const [3, 6, 12])
                  ActionChip(
                    label: Text('+$m tháng'),
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    onPressed: _currentEnd == null
                        ? null
                        : () => setState(() => _newEnd = ContractRules.addMonths(_currentEnd!, m)),
                  ),
              ],
            ),
          ],
          if (_type == 'PRICE_CHANGE') ...[
            InfoRow(label: 'Giá thuê hiện tại', value: Fmt.vnd(c.rentPrice)),
            const SizedBox(height: 8),
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Giá thuê mới (đ/tháng)'),
            ),
            const SizedBox(height: 12),
            DateField(
              label: 'Ngày bắt đầu áp dụng',
              value: _effective,
              onTap: () async {
                final d = await pickDate(context, initial: _effective);
                if (d != null) setState(() => _effective = d);
              },
            ),
            const SizedBox(height: 8),
            const NoticeBox(text: 'Giá mới chỉ áp dụng cho hóa đơn phát sinh sau ngày áp dụng; không áp dụng lùi vào kỳ đã thanh toán.'),
          ],
          if (_type == 'MANUAL_CLAUSE') ...[
            TextField(
              controller: _clause,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Nội dung điều khoản bổ sung'),
            ),
            const SizedBox(height: 12),
            DateField(
              label: 'Ngày hiệu lực',
              value: _effective,
              onTap: () async {
                final d = await pickDate(context, initial: _effective);
                if (d != null) setState(() => _effective = d);
              },
            ),
          ],
          if (_type == 'MOVE_OUT_NOTICE') ...[
            DateField(
              label: 'Ngày dự kiến trả phòng',
              value: _moveOut,
              onTap: () async {
                final d = await pickDate(context, initial: _moveOut ?? DateTime.now(), first: DateTime.now());
                if (d != null) setState(() => _moveOut = d);
              },
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _reason,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Lý do điều chỉnh *', hintText: 'Bắt buộc, dùng để ghi vết'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            NoticeBox(text: _error!, tone: Tone.red, icon: Icons.error_outline_rounded),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saving ? null : _submit,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Lưu phụ lục'),
          ),
        ],
      ),
    );
  }
}

// ─── UC67: Hủy hợp đồng ───────────────────────────────────────────────────

Future<bool> showCancelContractDialog(
  BuildContext context, {
  required ContractDetailResult contract,
  required List<ContractInvoiceSummary> invoices,
}) async {
  final block = ContractRules.cancelBlockReason(contract.status, invoices);
  if (block != null) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Không thể hủy hợp đồng'),
        content: Text(block, style: const TextStyle(fontSize: 14)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đã hiểu'))],
      ),
    );
    return false;
  }
  final ok = await _showSheet<bool>(context, _CancelSheet(contract: contract));
  return ok == true;
}

class _CancelSheet extends StatefulWidget {
  final ContractDetailResult contract;
  const _CancelSheet({required this.contract});

  @override
  State<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<_CancelSheet> {
  static const _presets = ['Khách bỏ cọc', 'Thỏa thuận lại', 'Khác'];
  String? _preset;
  final _detail = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  String get _reason {
    final detail = _detail.text.trim();
    if (_preset == null || _preset == 'Khác') return detail;
    return detail.isEmpty ? _preset! : '${_preset!}: $detail';
  }

  Future<void> _submit() async {
    if (_reason.isEmpty) {
      setState(() => _error = 'Vui lòng chọn hoặc nhập lý do hủy');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ContractService.cancel(widget.contract.id, reason: _reason);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = Fmt.errorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sheetTitle('Hủy hợp đồng ${widget.contract.displayCode}', 'Dùng khi khách đổi ý trước khi dọn vào ở.'),
          const NoticeBox(
            text: 'Hợp đồng chuyển sang Đã hủy, phòng trở về Trống. Thao tác không thể hoàn tác.',
            tone: Tone.red,
            icon: Icons.warning_amber_rounded,
          ),
          const SizedBox(height: 16),
          const Text('Lý do hủy *', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final p in _presets)
                ChoiceChip(
                  label: Text(p),
                  selected: _preset == p,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onSelected: (_) => setState(() => _preset = p),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _detail,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: _preset == 'Khác' || _preset == null ? 'Nhập lý do' : 'Ghi chú thêm (tùy chọn)',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            NoticeBox(text: _error!, tone: Tone.red, icon: Icons.error_outline_rounded),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: const Text('Giữ hợp đồng'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Hủy hợp đồng'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── UC80 bước 5b/5c: đóng hợp đồng sau khi thu thêm ──────────────────────

Future<bool> showFinalizeSettlementDialog(BuildContext context, {required int contractId, required SettlementStatus status}) async {
  final ok = await _showSheet<bool>(context, _FinalizeSheet(contractId: contractId, status: status));
  return ok == true;
}

class _FinalizeSheet extends StatefulWidget {
  final int contractId;
  final SettlementStatus status;
  const _FinalizeSheet({required this.contractId, required this.status});

  @override
  State<_FinalizeSheet> createState() => _FinalizeSheetState();
}

class _FinalizeSheetState extends State<_FinalizeSheet> {
  final _note = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool badDebt}) async {
    if (badDebt && _note.text.trim().isEmpty) {
      setState(() => _error = 'Vui lòng nhập ghi chú khi ghi nhận nợ xấu');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await SettlementService.finalize(widget.contractId, closeAsBadDebt: badDebt, note: badDebt ? _note.text.trim() : null);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = Fmt.errorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.status;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sheetTitle('Đóng hợp đồng', 'Hóa đơn tất toán #${s.settlementInvoiceId ?? '—'}'),
          InfoRow(label: 'Tổng tất toán', value: Fmt.vnd(s.settlementTotal)),
          InfoRow(
            label: 'Khách còn phải trả',
            value: Fmt.vnd(s.remainingAmount ?? 0),
            emphasize: true,
            valueColor: (s.remainingAmount ?? 0) > 0 ? ContractTokens.redText : ContractTokens.greenText,
          ),
          const SizedBox(height: 12),
          if (s.readyToClose) ...[
            const NoticeBox(text: 'Khách đã thanh toán hóa đơn tất toán. Xác nhận để thanh lý hợp đồng.', tone: Tone.green),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : () => _submit(badDebt: false),
              style: ElevatedButton.styleFrom(
                backgroundColor: ContractTokens.confirmGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Xác nhận & thanh lý hợp đồng'),
            ),
          ] else ...[
            const NoticeBox(
              text: 'Khách chưa thanh toán hóa đơn tất toán. Khi khách trả đủ, quay lại đây để thanh lý hợp đồng. '
                  'Nếu khách không trả, bạn có thể đóng hợp đồng và ghi nhận nợ xấu.',
              tone: Tone.amber,
              icon: Icons.hourglass_bottom_rounded,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Ghi chú nợ xấu *'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : () => _submit(badDebt: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Đóng hợp đồng & ghi nhận nợ xấu'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            NoticeBox(text: _error!, tone: Tone.red, icon: Icons.error_outline_rounded),
          ],
        ],
      ),
    );
  }
}
