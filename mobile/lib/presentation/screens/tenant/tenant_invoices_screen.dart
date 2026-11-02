import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/invoice_service.dart';
import '../../widgets/invoice_detail_sheet.dart';
import '../../widgets/viet_qr_payment_sheet.dart';
import '../manager/invoices/invoice_widgets.dart';
import 'invoices/tenant_transactions_screen.dart';

/// Module IX – Hóa đơn (Khách thuê): UC74 danh sách hóa đơn của mình, UC75 chi tiết + VietQR,
/// UC79 lịch sử thanh toán. Máy chủ chỉ trả hóa đơn của chính khách thuê (BR74.2).
class TenantInvoicesScreen extends StatefulWidget {
  const TenantInvoicesScreen({super.key});

  @override
  State<TenantInvoicesScreen> createState() => _TenantInvoicesScreenState();
}

class _TenantInvoicesScreenState extends State<TenantInvoicesScreen> {
  static const _statusTabs = [
    ('', 'Tất cả'),
    ('PENDING', 'Chờ thanh toán'),
    ('PARTIAL', 'Thanh toán một phần'),
    ('PAID', 'Đã thanh toán'),
  ];

  final List<InvoiceResult> _invoices = [];
  final _searchCtrl = TextEditingController();
  String _status = '';
  DateTime? _month;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 0;
  int _totalPages = 0;
  int _totalElements = 0;

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
      final res = await InvoiceService.listMine(
        status: _status,
        billingMonth: _month == null ? null : billingMonthKey(_month!),
        page: 0,
        size: InvoiceService.pageSize,
      );
      if (!mounted) return;
      setState(() {
        _invoices
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
      final res = await InvoiceService.listMine(
        status: _status,
        billingMonth: _month == null ? null : billingMonthKey(_month!),
        page: _page + 1,
        size: InvoiceService.pageSize,
      );
      if (!mounted) return;
      setState(() {
        _invoices.addAll(res.content);
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

  void _applyFilter(VoidCallback change) {
    setState(change);
    _load();
  }

  void _openDetail(InvoiceResult inv) {
    InvoiceDetailSheet.show(context, invoiceId: inv.id, initialInvoice: inv, onPaymentSuccess: _load);
  }

  void _openPayment(InvoiceResult inv) {
    VietQrPaymentSheet.show(context, invoiceId: inv.id, onSuccess: _load);
  }

  @override
  Widget build(BuildContext context) {
    final visible = filterInvoices(_invoices, query: _searchCtrl.text);
    return Scaffold(
      backgroundColor: InvoiceTones.paper,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: invoiceInputDecoration(
                      'Tìm hóa đơn',
                      hint: 'Mã HĐ, kỳ thanh toán',
                      prefixIcon: const Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'Lịch sử thanh toán',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TenantTransactionsScreen()),
                  ),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(52, 52),
                    side: const BorderSide(color: InvoiceTones.hairline),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.history_rounded, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: InvoiceButtonStyles.outlined(),
                    onPressed: () async {
                      final picked = await pickBillingMonth(context, initial: _month ?? DateTime.now());
                      if (picked != null) _applyFilter(() => _month = picked);
                    },
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: Text(_month == null ? 'Mọi kỳ hóa đơn' : formatBillingMonth(billingMonthKey(_month!))),
                  ),
                ),
                if (_month != null)
                  IconButton(
                    tooltip: 'Bỏ lọc kỳ',
                    onPressed: () => _applyFilter(() => _month = null),
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final tab in _statusTabs)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InvoiceFilterChip(
                        label: tab.$2,
                        selected: _status == tab.$1,
                        onTap: () => _applyFilter(() => _status = tab.$1),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 64),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
              )
            else if (_error != null)
              _message(Icons.error_outline_rounded, 'Không tải được hóa đơn', _error!, retry: true)
            else if (visible.isEmpty)
              _message(
                Icons.receipt_long_outlined,
                'Không có hóa đơn',
                _invoices.isEmpty ? 'Chưa có hóa đơn nào khớp bộ lọc.' : 'Không có hóa đơn khớp từ khóa.',
              )
            else ...[
              InvoiceSummaryCard(
                totals: InvoiceTotals.of(visible),
                caption: _invoices.length < _totalElements
                    ? 'Đã tải ${_invoices.length}/$_totalElements hóa đơn'
                    : '${visible.length} hóa đơn',
              ),
              const SizedBox(height: 12),
              for (final inv in visible) _card(inv),
              if (_page + 1 < _totalPages)
                OutlinedButton(
                  style: InvoiceButtonStyles.outlined(),
                  onPressed: _loadingMore ? null : _loadMore,
                  child: Text(_loadingMore ? 'Đang tải...' : 'Xem thêm hóa đơn cũ hơn'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _message(IconData icon, String title, String body, {bool retry = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 8),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: InvoiceTones.heading)),
            const SizedBox(height: 4),
            Text(body, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: InvoiceTones.muted)),
            if (retry) ...[
              const SizedBox(height: 14),
              OutlinedButton(style: InvoiceButtonStyles.outlined(), onPressed: _load, child: const Text('Thử lại')),
            ],
          ],
        ),
      );

  Widget _card(InvoiceResult inv) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: InvoiceTones.hairline),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openDetail(inv),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(formatBillingMonth(inv.billingMonth),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: InvoiceTones.heading)),
                          const SizedBox(height: 2),
                          Text(
                            '${inv.roomLabel} · #${inv.id}'
                            '${inv.dueDate != null ? ' · Hạn ${formatDateVi(inv.dueDate)}' : ''}',
                            style: const TextStyle(fontSize: 12, color: InvoiceTones.muted),
                          ),
                        ],
                      ),
                    ),
                    InvoiceStatusBadge(inv.status),
                  ],
                ),
                const SizedBox(height: 12),
                InvoiceAmountTriple(
                  total: inv.totalAmount,
                  paid: inv.paidAmount,
                  remaining: inv.isVoid ? 0 : inv.remainingAmount,
                  dense: true,
                ),
                if (inv.isUnpaid && inv.remainingAmount > 0) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: InvoiceButtonStyles.confirm(),
                    onPressed: () => _openPayment(inv),
                    icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                    label: Text('Thanh toán ${formatVnd(inv.remainingAmount)}'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
