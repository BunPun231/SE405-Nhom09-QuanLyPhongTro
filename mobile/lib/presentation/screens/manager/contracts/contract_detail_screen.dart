import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/contract_service.dart';
import '../../../../core/services/settlement_service.dart';
import '../../../../core/utils/media_helper.dart';
import 'contract_action_sheets.dart';
import 'contract_ui.dart';
import 'settlement_wizard.dart';

/// UC65 – Chi tiết hợp đồng (Quản lý và Khách thuê). Quản lý có thêm các thao tác
/// UC66 (điều chỉnh), UC67 (hủy), UC68 (PDF), UC69 (thu cọc), UC80 (tất toán).
class ContractDetailScreen extends StatefulWidget {
  final int contractId;
  final bool isManager;
  const ContractDetailScreen({super.key, required this.contractId, this.isManager = true});

  @override
  State<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends State<ContractDetailScreen> {
  ContractDetailResult? _c;
  List<ContractAppendixResult> _appendices = [];
  List<ContractInvoiceSummary> _invoices = [];
  SettlementStatus? _settlement;
  bool _loading = true;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await ContractService.getDetail(widget.contractId);
      final results = await Future.wait<dynamic>([
        ContractService.getAllAppendices(widget.contractId).catchError((_) => <ContractAppendixResult>[]),
        ContractService.listInvoices(widget.contractId).catchError((_) => <ContractInvoiceSummary>[]),
        if (widget.isManager)
          SettlementService.getStatus(widget.contractId).then<SettlementStatus?>((s) => s).catchError((_) => null),
      ]);
      if (!mounted) return;
      setState(() {
        _c = detail;
        _appendices = results[0] as List<ContractAppendixResult>;
        _invoices = results[1] as List<ContractInvoiceSummary>;
        _settlement = widget.isManager ? results[2] as SettlementStatus? : null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = Fmt.errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportPdf() async {
    final c = _c;
    if (c == null) return;
    setState(() => _busy = true);
    try {
      final room = (c.roomNumber ?? '${c.roomId}').replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
      await MediaHelper.downloadAndOpen(
        ContractService.pdfEndpoint(c.id),
        fileName: 'HopDong_${room}_${c.id}.pdf',
      );
    } catch (e) {
      if (mounted) showSnack(context, 'Đã xảy ra lỗi khi tạo file, vui lòng thử lại sau. (${Fmt.errorText(e)})', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _attach() async {
    final picked = await MediaHelper.pickImage(context, maxWidth: 1600);
    if (picked == null) return;
    setState(() => _busy = true);
    try {
      await ContractService.addAttachment(widget.contractId, fileName: picked.name, base64Data: picked.base64);
      if (mounted) showSnack(context, 'Đã đính kèm tệp');
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, Fmt.errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _run(Future<bool> Function() action, String success) async {
    final ok = await action();
    if (ok && mounted) {
      showSnack(context, success);
      await _load();
    }
  }

  bool get _isPrimaryViewer => widget.isManager || ApiClient.userId == _c?.primaryResidentUserId;

  /// BR65.2: Khách thuê phụ chỉ thấy SĐT người đứng tên đã che một phần.
  String _maskPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '—';
    if (_isPrimaryViewer || phone.length < 6) return phone;
    return '${phone.substring(0, 3)}****${phone.substring(phone.length - 3)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(_c?.displayCode ?? 'Chi tiết hợp đồng'),
        actions: [
          if (widget.isManager && _c != null)
            IconButton(
              tooltip: 'Xuất PDF hợp đồng',
              onPressed: _busy ? null : _exportPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
            ),
          IconButton(tooltip: 'Tải lại', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading && _c == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
          : _c == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NoticeBox(
                          text: 'Không thể tải dữ liệu hợp đồng. ${_error ?? ''}',
                          tone: Tone.red,
                          icon: Icons.error_outline_rounded,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(onPressed: _load, child: const Text('Thử lại')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      if (_busy) const LinearProgressIndicator(minHeight: 2),
                      _header(_c!),
                      if (widget.isManager) _actions(_c!),
                      _terms(_c!),
                      _deposit(_c!),
                      _attachments(),
                      _amendments(),
                      _invoicesCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _header(ContractDetailResult c) {
    final tone = contractTone(c.status, c.endDate);
    return SectionCard(
      title: 'Phòng ${c.roomNumber ?? '#${c.roomId}'}',
      icon: Icons.meeting_room_outlined,
      trailing: StatusBadge(label: contractStatusText(c.status, c.endDate), tone: tone),
      child: Column(
        children: [
          InfoRow(label: 'Khu trọ', value: c.motelName ?? '—'),
          InfoRow(label: 'Người đứng tên', value: c.primaryResidentFullName ?? 'Khách thuê'),
          InfoRow(label: 'Số điện thoại', value: _maskPhone(c.primaryResidentPhone)),
          InfoRow(label: 'Số người ở', value: '${c.residentUserIds.isEmpty ? 1 : c.residentUserIds.length} người'),
          InfoRow(label: 'Ngày lập', value: Fmt.date(c.createdAt)),
          if (c.cancelReason != null && c.cancelReason!.isNotEmpty)
            InfoRow(label: 'Lý do hủy', value: c.cancelReason!, valueColor: ContractTokens.redText),
          if (c.intendedMoveOutDate != null)
            InfoRow(label: 'Dự kiến trả phòng', value: Fmt.date(c.intendedMoveOutDate), valueColor: ContractTokens.amberText),
          if (ContractRules.isExpiringSoon(c.status, c.endDate)) ...[
            const SizedBox(height: 8),
            const NoticeBox(text: 'Hợp đồng sắp hết hạn trong 30 ngày tới. Cân nhắc gia hạn.', tone: Tone.amber, icon: Icons.schedule_rounded),
          ],
        ],
      ),
    );
  }

  Widget _actions(ContractDetailResult c) {
    final s = _settlement;
    final active = c.status == 'ACTIVE';
    final canCollect = c.depositStatus == 'UNPAID' && (c.status == 'DRAFT' || active);
    final canSettle = (active || c.status == 'PENDING_LIQUIDATION') && c.depositStatus != 'UNPAID' && !(s?.hasSettlement ?? false);
    final canFinalize = s != null && (s.awaitingExtraPayment || s.readyToClose);
    final canCancel = c.status == 'DRAFT' || active;
    final buttons = <Widget>[
      if (canCollect)
        _actionButton(Icons.payments_outlined, 'Ghi nhận thu cọc', confirm: true, onTap: () => _run(
              () => showDepositCollectSheet(context, contractId: c.id, depositAmount: c.depositAmount, willActivate: c.status == 'DRAFT'),
              'Đã ghi nhận thu cọc',
            )),
      if (canFinalize)
        _actionButton(Icons.task_alt_rounded, s.readyToClose ? 'Thanh lý hợp đồng' : 'Chờ thu thêm · Đóng HĐ',
            confirm: s.readyToClose,
            onTap: () => _run(() => showFinalizeSettlementDialog(context, contractId: c.id, status: s), 'Đã đóng hợp đồng')),
      if (canSettle)
        _actionButton(Icons.calculate_outlined, 'Tất toán trả phòng', onTap: () async {
          final done = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => SettlementWizard(contract: c)),
          );
          if (done == true) await _load();
        }),
      if (active)
        _actionButton(Icons.edit_note_rounded, 'Điều chỉnh / Gia hạn',
            onTap: () => _run(() => showAdjustSheet(context, contract: c), 'Đã lưu phụ lục hợp đồng')),
      _actionButton(Icons.picture_as_pdf_outlined, 'Xuất PDF', onTap: _exportPdf),
      if (canCancel)
        _actionButton(Icons.cancel_outlined, 'Hủy hợp đồng', danger: true,
            onTap: () => _run(() => showCancelContractDialog(context, contract: c, invoices: _invoices), 'Đã hủy hợp đồng')),
    ];
    return SectionCard(
      title: 'Thao tác',
      icon: Icons.bolt_rounded,
      child: Wrap(spacing: 8, runSpacing: 8, children: buttons),
    );
  }

  Widget _actionButton(IconData icon, String label, {required VoidCallback onTap, bool confirm = false, bool danger = false}) {
    if (confirm) {
      return ElevatedButton.icon(
        onPressed: _busy ? null : onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: ContractTokens.confirmGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: _busy ? null : onTap,
      icon: Icon(icon, size: 18, color: danger ? ContractTokens.redText : AppColors.primary),
      label: Text(label, style: TextStyle(color: danger ? ContractTokens.redText : AppColors.textPrimaryLight)),
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
    );
  }

  Widget _terms(ContractDetailResult c) {
    final start = DateTime.tryParse(c.startDate);
    final end = DateTime.tryParse(c.endDate);
    final months = start != null && end != null ? ContractRules.durationMonths(start, end) : null;
    return SectionCard(
      title: 'Điều khoản',
      icon: Icons.gavel_rounded,
      child: Column(
        children: [
          InfoRow(label: 'Ngày bắt đầu', value: Fmt.date(c.startDate)),
          InfoRow(label: 'Ngày kết thúc', value: Fmt.date(c.endDate)),
          if (months != null) InfoRow(label: 'Thời hạn', value: '$months tháng'),
          InfoRow(label: 'Giá thuê', value: '${Fmt.vnd(c.rentPrice)}/tháng', emphasize: true),
          InfoRow(label: 'Kỳ đóng tiền', value: '${c.paymentCycleMonths ?? 1} tháng/lần'),
          InfoRow(
            label: 'Ngày chốt sổ',
            value: (c.billingCycleDay ?? 31) >= 31 ? 'Cuối tháng' : 'Ngày ${c.billingCycleDay}',
          ),
          InfoRow(label: 'Kỳ thu đầu tiên', value: Fmt.date(c.billingDate)),
          InfoRow(label: 'Dịch vụ đi kèm', value: '${c.serviceItems.length} dịch vụ'),
        ],
      ),
    );
  }

  Widget _deposit(ContractDetailResult c) {
    final records = _appendices.where((a) => a.isDepositRecord).toList();
    return SectionCard(
      title: 'Tiền cọc',
      icon: Icons.savings_outlined,
      trailing: StatusBadge(label: ContractRules.depositLabel(c.depositStatus), tone: depositTone(c.depositStatus)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(label: 'Số tiền cọc', value: Fmt.vnd(c.depositAmount), emphasize: true),
          if (records.isEmpty && c.depositStatus == 'UNPAID')
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: NoticeBox(text: 'Chưa thu cọc. Hợp đồng chỉ có hiệu lực sau khi xác nhận đã thu.', tone: Tone.amber),
            ),
          for (final r in records)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: ContractTokens.mist, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: ContractTokens.greenText, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đã thu ${Fmt.vnd(double.tryParse('${r.meta['amount']}') ?? c.depositAmount)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ContractTokens.heading),
                          ),
                          Text(
                            '${Fmt.date(r.meta['collectedDate']?.toString() ?? r.effectiveDate)} · '
                            '${ContractRules.paymentMethodLabel(r.meta['paymentMethod']?.toString())}'
                            '${r.meta['note'] != null ? ' · ${r.meta['note']}' : ''}',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (c.depositStatus == 'REFUNDED' || c.depositStatus == 'DEDUCTED')
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Cọc đã được xử lý trong bảng tất toán (trừ công nợ/hư hỏng, hoàn phần còn lại).',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
            ),
        ],
      ),
    );
  }

  Widget _attachments() {
    final files = _appendices.where((a) => a.isAttachment).toList();
    return SectionCard(
      title: 'Tệp đính kèm (${files.length})',
      icon: Icons.attach_file_rounded,
      trailing: widget.isManager
          ? IconButton(
              tooltip: 'Đính kèm bản scan',
              onPressed: _busy ? null : _attach,
              icon: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
            )
          : null,
      child: files.isEmpty
          ? const Text('Chưa có tệp đính kèm.', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight))
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in files)
                  Tooltip(
                    message: f.meta['name']?.toString() ?? 'Tệp đính kèm',
                    child: Material(
                      color: ContractTokens.mist,
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _viewImage(f.meta['url']?.toString()),
                        child: SizedBox(
                          width: 88,
                          height: 88,
                          child: f.meta['url'] == null
                              ? const Icon(Icons.insert_drive_file_outlined)
                              : Image.network(
                                  f.meta['url'].toString(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
                                ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  void _viewImage(String? url) {
    if (url == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(tooltip: 'Đóng', onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
            ),
            Flexible(child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain))),
          ],
        ),
      ),
    );
  }

  Widget _amendments() {
    final items = _appendices.where((a) => a.isAmendment).toList();
    return SectionCard(
      title: 'Phụ lục & lịch sử điều chỉnh',
      icon: Icons.history_rounded,
      child: items.isEmpty
          ? const Text('Chưa có phụ lục.', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight))
          : Column(
              children: [
                for (final a in items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: Tone.blue.bg, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.note_add_outlined, size: 18, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ContractRules.appendixLabel(a.type),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ContractTokens.heading)),
                              Text(
                                [
                                  'Hiệu lực ${Fmt.date(a.effectiveDate)}',
                                  if (a.newRentPrice != null) 'Giá mới ${Fmt.vnd(a.newRentPrice)}',
                                  if (a.newEndDate != null) 'Kết thúc mới ${Fmt.date(a.newEndDate)}',
                                ].join(' · '),
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                              ),
                              if (a.clause != null)
                                Text('Điều khoản: ${a.clause}', style: const TextStyle(fontSize: 13, color: ContractTokens.heading)),
                              if (a.reason != null)
                                Text('Lý do: ${a.reason}', style: const TextStyle(fontSize: 13, color: ContractTokens.slateText)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _invoicesCard() {
    final debt = _invoices.where((i) => i.isOutstanding).fold<double>(0, (s, i) => s + i.remainingAmount);
    final paid = _invoices.where((i) => i.status != 'VOID').fold<double>(0, (s, i) => s + i.paidAmount + i.balanceDeduction);
    return SectionCard(
      title: 'Hóa đơn & thanh toán',
      icon: Icons.receipt_long_outlined,
      child: Column(
        children: [
          InfoRow(label: 'Đã thanh toán', value: Fmt.vnd(paid), valueColor: ContractTokens.greenText),
          InfoRow(label: 'Còn nợ', value: Fmt.vnd(debt), valueColor: debt > 0 ? ContractTokens.redText : ContractTokens.heading),
          const Divider(height: 20),
          if (_invoices.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Chưa có hóa đơn.', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
            ),
          for (final inv in _invoices)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inv.invoiceType == 'SETTLEMENT' ? 'Hóa đơn tất toán #${inv.id}' : '${Fmt.month(inv.billingMonth)} · #${inv.id}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ContractTokens.heading),
                        ),
                        Text(
                          'Tổng ${Fmt.vnd(inv.totalAmount)} · Đã trả ${Fmt.vnd(inv.paidAmount + inv.balanceDeduction)}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(label: _invoiceLabel(inv.status), tone: _invoiceTone(inv.status)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _invoiceLabel(String s) {
    switch (s) {
      case 'PAID':
        return 'Đã thu';
      case 'PARTIAL':
        return 'Thu một phần';
      case 'VOID':
        return 'Vô hiệu';
      default:
        return 'Chờ thu';
    }
  }

  Tone _invoiceTone(String s) {
    switch (s) {
      case 'PAID':
        return Tone.green;
      case 'PARTIAL':
        return Tone.amber;
      case 'VOID':
        return Tone.slate;
      default:
        return Tone.red;
    }
  }
}
