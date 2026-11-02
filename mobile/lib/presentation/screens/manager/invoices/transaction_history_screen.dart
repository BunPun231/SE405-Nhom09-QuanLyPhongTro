import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/invoice_service.dart';
import '../../../widgets/invoice_detail_sheet.dart';
import 'invoice_widgets.dart';

/// UC79: Lịch sử giao dịch (ngày, số tiền, phương thức, mã tham chiếu, hóa đơn liên kết),
/// có tìm kiếm, lọc và xuất CSV. Dùng chung cho Quản lý ([isManager] = true) và Khách thuê.
class TransactionHistoryScreen extends StatefulWidget {
  final bool isManager;
  const TransactionHistoryScreen({super.key, required this.isManager});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  static const _pageSize = 50;

  final List<TransactionResult> _items = [];
  final _searchCtrl = TextEditingController();
  bool _loading = true;
  bool _loadingMore = false;
  bool _exporting = false;
  String? _error;
  int _page = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  String _method = '';
  String _status = '';
  DateTimeRange? _range;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await PaymentService.transactions(page: 0, size: _pageSize);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(res.content);
        _page = 0;
        _totalPages = res.totalPages;
        _totalElements = res.totalElements;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = cleanError(e);
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page + 1 >= _totalPages) return;
    setState(() => _loadingMore = true);
    try {
      final res = await PaymentService.transactions(page: _page + 1, size: _pageSize);
      if (!mounted) return;
      setState(() {
        _items.addAll(res.content);
        _page = res.number;
        _totalPages = res.totalPages;
        _loadingMore = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMore = false);
        showInvoiceSnack(context, cleanError(e), error: true);
      }
    }
  }

  List<TransactionResult> get _filtered => filterTransactions(
        _items,
        query: _searchCtrl.text,
        method: _method,
        status: _status,
        from: _range?.start,
        to: _range?.end,
      );

  Future<void> _export() async {
    final rows = _filtered;
    if (rows.isEmpty) {
      showInvoiceSnack(context, 'Không có giao dịch nào để xuất.');
      return;
    }
    setState(() => _exporting = true);
    try {
      final path = await PaymentService.exportCsv(rows);
      if (mounted) showInvoiceSnack(context, 'Đã xuất ${rows.length} giao dịch: $path');
    } catch (e) {
      if (mounted) showInvoiceSnack(context, 'Không xuất được file: ${cleanError(e)}', error: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _range,
      helpText: 'Chọn khoảng thời gian',
      saveText: 'Áp dụng',
    );
    if (picked != null) setState(() => _range = picked);
  }

  Future<void> _reconcile(TransactionResult tx) async {
    final ctrl = TextEditingController();
    final invoiceId = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gán hóa đơn thủ công', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Giao dịch ${tx.transactionRef ?? '#${tx.id}'} · ${formatVnd(tx.amount)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: invoiceInputDecoration('Mã hóa đơn', hint: 'VD: 125'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: InvoiceButtonStyles.confirm(),
            onPressed: () {
              final id = int.tryParse(ctrl.text.trim().replaceFirst('#', ''));
              if (id != null) Navigator.pop(ctx, id);
            },
            child: const Text('Xác nhận gán'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (invoiceId == null || !mounted) return;
    try {
      await PaymentService.reconcile(transactionId: tx.id, invoiceId: invoiceId);
      if (!mounted) return;
      showInvoiceSnack(context, 'Đã gán giao dịch cho hóa đơn #$invoiceId.');
      _load();
    } catch (e) {
      if (mounted) showInvoiceSnack(context, cleanError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;
    final total = rows.where((t) => t.status == 'SUCCESS').fold<double>(0, (s, t) => s + t.amount);
    return Scaffold(
      backgroundColor: InvoiceTones.paper,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(widget.isManager ? 'Lịch sử giao dịch' : 'Lịch sử thanh toán',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: InvoiceTones.ink)),
        actions: [
          IconButton(
            tooltip: 'Xuất file CSV',
            onPressed: _exporting || _loading ? null : _export,
            icon: _exporting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.file_download_outlined),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: InvoiceTones.hairline),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: invoiceInputDecoration(
                'Tìm kiếm',
                hint: 'Mã tham chiếu, mã hóa đơn, số tiền',
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final m in const [('', 'Mọi phương thức'), ('VIETQR', 'VietQR'), ('CASH', 'Tiền mặt'), ('BANK_TRANSFER', 'Chuyển khoản')])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InvoiceFilterChip(
                        label: m.$2,
                        selected: _method == m.$1,
                        onTap: () => setState(() => _method = m.$1),
                      ),
                    ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final s in const [('', 'Mọi trạng thái'), ('SUCCESS', 'Thành công'), ('PENDING_RECONCILE', 'Chờ đối soát'), ('FAILED', 'Thất bại')])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InvoiceFilterChip(
                        label: s.$2,
                        selected: _status == s.$1,
                        onTap: () => setState(() => _status = s.$1),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: InvoiceButtonStyles.outlined(),
                    onPressed: _pickRange,
                    icon: const Icon(Icons.date_range_rounded),
                    label: Text(
                      _range == null
                          ? 'Mọi thời gian'
                          : '${formatDateVi(_range!.start.toIso8601String())} – ${formatDateVi(_range!.end.toIso8601String())}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (_range != null)
                  IconButton(
                    tooltip: 'Bỏ lọc thời gian',
                    onPressed: () => setState(() => _range = null),
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (!_loading && _error == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${rows.length} giao dịch · Thành công ${formatVnd(total)}'
                  '${_items.length < _totalElements ? ' (đã tải ${_items.length}/$_totalElements)' : ''}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: InvoiceTones.muted),
                ),
              ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
              )
            else if (_error != null)
              _message(Icons.error_outline_rounded, 'Không tải được lịch sử', _error!, retry: true)
            else if (rows.isEmpty)
              _message(Icons.receipt_outlined, 'Chưa có giao dịch nào',
                  _items.isEmpty ? 'Các lần thanh toán sẽ hiển thị tại đây.' : 'Không có giao dịch khớp bộ lọc.')
            else ...[
              for (final t in rows) _tile(t),
              if (_page + 1 < _totalPages)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton(
                    style: InvoiceButtonStyles.outlined(),
                    onPressed: _loadingMore ? null : _loadMore,
                    child: Text(_loadingMore ? 'Đang tải...' : 'Tải thêm giao dịch cũ hơn'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _message(IconData icon, String title, String body, {bool retry = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(icon, size: 44, color: InvoiceTones.muted),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: InvoiceTones.heading)),
            const SizedBox(height: 4),
            Text(body, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: InvoiceTones.muted)),
            if (retry) ...[
              const SizedBox(height: 12),
              OutlinedButton(style: InvoiceButtonStyles.outlined(), onPressed: _load, child: const Text('Thử lại')),
            ],
          ],
        ),
      );

  Widget _tile(TransactionResult t) {
    final warn = t.needsReconcile;
    final statusColor = t.status == 'SUCCESS'
        ? InvoiceTones.paidText
        : (t.status == 'FAILED' ? InvoiceTones.dangerText : InvoiceTones.pendingText);
    final methodIcon = t.paymentMethod == 'VIETQR'
        ? Icons.qr_code_2_rounded
        : (t.paymentMethod == 'CASH' ? Icons.payments_outlined : Icons.account_balance_outlined);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: warn ? InvoiceTones.dangerText.withValues(alpha: 0.4) : InvoiceTones.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (warn ? AppColors.danger : AppColors.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(warn ? Icons.warning_amber_rounded : methodIcon,
                    color: warn ? InvoiceTones.dangerText : AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formatVnd(t.amount),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: InvoiceTones.ink)),
                    const SizedBox(height: 2),
                    Text(
                      '${formatDateVi(t.paidAt, withTime: true)} · ${paymentMethodLabel(t.paymentMethod)}'
                      '${t.bankCode != null && t.bankCode!.isNotEmpty ? ' · ${t.bankCode}' : ''}',
                      style: const TextStyle(fontSize: 13, color: InvoiceTones.muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(transactionStatusLabel(t.status),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Mã tham chiếu: ${t.transactionRef ?? '-'}',
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: InvoiceTones.heading)),
          if (t.isOverpaid)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Trả thừa ${formatVnd(t.overpaidAmount)} → cộng vào số dư',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6D28D9))),
            ),
          Row(
            children: [
              if (t.invoiceId != null)
                TextButton.icon(
                  onPressed: () => InvoiceDetailSheet.show(
                    context,
                    invoiceId: t.invoiceId!,
                    isManager: widget.isManager,
                    onPaymentSuccess: _load,
                  ),
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: Text('Hóa đơn #${t.invoiceId}'),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Chưa gán hóa đơn',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: InvoiceTones.dangerText)),
                ),
              const Spacer(),
              if (widget.isManager && t.status == 'PENDING_RECONCILE')
                TextButton.icon(
                  onPressed: () => _reconcile(t),
                  icon: const Icon(Icons.link_rounded, size: 18),
                  label: const Text('Gán hóa đơn'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
