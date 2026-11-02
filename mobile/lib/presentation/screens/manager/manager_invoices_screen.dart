import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/invoice_service.dart';
import '../../../core/services/motel_service.dart';
import '../../widgets/invoice_detail_sheet.dart';
import 'invoices/invoice_generate_sheet.dart';
import 'invoices/invoice_widgets.dart';
import 'invoices/manual_payment_sheet.dart';
import 'invoices/transaction_history_screen.dart';

/// Module IX – Hóa đơn (Quản lý): UC73 tạo hóa đơn, UC74 danh sách & lọc, UC75 chi tiết,
/// UC76 hủy & tái cấp, UC77 xóa, UC78 ghi nhận thu tiền / đối soát, UC79 lịch sử giao dịch.
class ManagerInvoicesScreen extends StatefulWidget {
  const ManagerInvoicesScreen({super.key});

  @override
  State<ManagerInvoicesScreen> createState() => _ManagerInvoicesScreenState();
}

class _ManagerInvoicesScreenState extends State<ManagerInvoicesScreen> {
  static const _statusTabs = [
    ('', 'Tất cả'),
    ('PENDING', 'Chờ thanh toán'),
    ('PARTIAL', 'Thanh toán một phần'),
    ('PAID', 'Đã thanh toán'),
    ('VOID', 'Đã hủy'),
  ];

  List<InvoiceResult> _invoices = [];
  List<MotelResult> _motels = [];
  List<RoomResult> _rooms = [];
  int? _motelId;
  int? _roomId;
  DateTime? _month;
  String _status = '';
  final _searchCtrl = TextEditingController();
  bool _loading = true;
  String? _error;
  int _page = 0;
  int _totalPages = 0;
  int _totalElements = 0;

  @override
  void initState() {
    super.initState();
    _loadMotels();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMotels() async {
    try {
      final res = await MotelService.list(size: 50);
      if (mounted) setState(() => _motels = res.content);
    } catch (_) {
      // Không chặn danh sách hóa đơn nếu không tải được khu trọ.
    }
    await _loadInvoices();
  }

  Future<void> _loadRooms(int? motelId) async {
    setState(() {
      _rooms = [];
      _roomId = null;
    });
    if (motelId == null) return;
    try {
      final res = await RoomService.list(motelId, size: 200);
      if (mounted && _motelId == motelId) setState(() => _rooms = res.content);
    } catch (_) {}
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await InvoiceService.list(
        motelId: _motelId,
        status: _status,
        billingMonth: _month == null ? null : billingMonthKey(_month!),
        roomId: _roomId,
        page: _page,
        size: InvoiceService.pageSize,
      );
      if (!mounted) return;
      setState(() {
        _invoices = res.content;
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

  void _applyFilter(VoidCallback change) {
    setState(() {
      change();
      _page = 0;
    });
    _loadInvoices();
  }

  Future<void> _openGenerate() async {
    final outcome = await showInvoiceGenerateSheet(context, motels: _motels, initialMotelId: _motelId);
    if (outcome == null || !outcome.ran || !mounted) return;
    if (outcome.viewMonth != null) {
      if (outcome.motelId != _motelId) {
        _motelId = outcome.motelId;
        _loadRooms(_motelId);
      }
      _applyFilter(() {
        _month = outcome.viewMonth;
        _status = '';
      });
    } else {
      _loadInvoices();
    }
  }

  void _openDetail(InvoiceResult inv) {
    InvoiceDetailSheet.show(
      context,
      invoiceId: inv.id,
      initialInvoice: inv,
      isManager: true,
      onChanged: _loadInvoices,
    );
  }

  Future<void> _recordPayment(InvoiceResult inv) async {
    final ok = await showManualPaymentSheet(context, inv);
    if (ok == true && mounted) {
      showInvoiceSnack(context, 'Đã ghi nhận thanh toán cho hóa đơn #${inv.id}.');
      _loadInvoices();
    }
  }

  void _openTransactions() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TransactionHistoryScreen(isManager: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = filterInvoices(_invoices, query: _searchCtrl.text);
    return Scaffold(
      backgroundColor: InvoiceTones.paper,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'manager-invoices-generate',
        onPressed: _openGenerate,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tạo hóa đơn', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadInvoices,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            _filters(),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 64),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
              )
            else if (_error != null)
              _message(Icons.error_outline_rounded, 'Không tải được hóa đơn', _error!, action: ('Thử lại', _loadInvoices))
            else if (_invoices.isEmpty)
              _message(
                Icons.receipt_long_outlined,
                'Chưa có hóa đơn',
                'Không có hóa đơn khớp bộ lọc. Bấm "Tạo hóa đơn" để lập hóa đơn tháng.',
                action: ('Tạo hóa đơn', _openGenerate),
              )
            else ...[
              InvoiceSummaryCard(
                totals: InvoiceTotals.of(visible),
                caption: _totalPages > 1
                    ? 'Trang ${_page + 1}/$_totalPages · ${visible.length} hóa đơn (tổng $_totalElements)'
                    : '${visible.length} hóa đơn',
              ),
              const SizedBox(height: 12),
              if (visible.isEmpty)
                _message(Icons.search_off_rounded, 'Không tìm thấy', 'Không có hóa đơn khớp từ khóa trong trang này.')
              else
                for (final inv in visible) _card(inv),
              if (_totalPages > 1) _pager(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filters() {
    final selectedMotel = _motels.where((m) => m.id == _motelId).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: invoiceInputDecoration(
                  'Tìm trong trang',
                  hint: 'Mã HĐ, số phòng',
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              tooltip: 'Lịch sử giao dịch',
              onPressed: _openTransactions,
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
              child: _dropdown<int?>(
                value: _motelId,
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Mọi khu trọ')),
                  ..._motels.map((m) => DropdownMenuItem<int?>(
                        value: m.id,
                        child: Text(m.name, overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: (v) {
                  _applyFilter(() => _motelId = v);
                  _loadRooms(v);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _dropdown<int?>(
                value: _roomId,
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(selectedMotel.isEmpty ? 'Chọn khu để lọc phòng' : 'Mọi phòng',
                        overflow: TextOverflow.ellipsis),
                  ),
                  ..._rooms.map((r) => DropdownMenuItem<int?>(value: r.id, child: Text('Phòng ${r.roomNumber}'))),
                ],
                onChanged: _rooms.isEmpty ? null : (v) => _applyFilter(() => _roomId = v),
              ),
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
      ],
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
  }) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: InvoiceTones.hairline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          borderRadius: BorderRadius.circular(14),
          style: const TextStyle(fontSize: 13, color: InvoiceTones.heading, fontWeight: FontWeight.w600),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _message(IconData icon, String title, String body, {(String, VoidCallback)? action}) => Padding(
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
            if (action != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(style: InvoiceButtonStyles.outlined(), onPressed: action.$2, child: Text(action.$1)),
            ],
          ],
        ),
      );

  Widget _pager() => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.outlined(
              tooltip: 'Trang trước',
              onPressed: _page == 0
                  ? null
                  : () {
                      setState(() => _page--);
                      _loadInvoices();
                    },
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Trang ${_page + 1} / $_totalPages',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: InvoiceTones.heading)),
            ),
            IconButton.outlined(
              tooltip: 'Trang sau',
              onPressed: _page >= _totalPages - 1
                  ? null
                  : () {
                      setState(() => _page++);
                      _loadInvoices();
                    },
              icon: const Icon(Icons.chevron_right_rounded),
            ),
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
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: InvoiceTones.statusTint(inv.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.receipt_long_rounded, color: InvoiceTones.statusColor(inv.status), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${inv.roomLabel} · #${inv.id}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: InvoiceTones.heading)),
                          const SizedBox(height: 2),
                          Text(
                            '${formatBillingMonth(inv.billingMonth)}'
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
                if (inv.isUnpaid) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      style: InvoiceButtonStyles.confirm(),
                      onPressed: () => _recordPayment(inv),
                      icon: const Icon(Icons.payments_rounded, size: 18),
                      label: const Text('Ghi nhận đã thu'),
                    ),
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
