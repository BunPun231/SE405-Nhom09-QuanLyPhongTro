import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/invoice_service.dart';
import '../../../core/services/motel_service.dart';

// ─── helpers ────────────────────────────────────────────────────────────────
String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
String _fmtMonth(String? raw) {
  if (raw == null || raw.isEmpty) return '-';
  try {
    final d = DateTime.parse(raw);
    return 'Tháng ${d.month}/${d.year}';
  } catch (_) { return raw.substring(0, 7); }
}
String _fmtDate(String? raw) {
  if (raw == null || raw.isEmpty) return '-';
  try {
    final d = DateTime.parse(raw);
    return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  } catch (_) { return raw; }
}

Widget _statusBadge(String status) {
  Color color; String label;
  switch (status) {
    case 'PAID': color = AppColors.success; label = 'Đã thu'; break;
    case 'PARTIAL': color = const Color(0xFF3B82F6); label = 'Một phần'; break;
    case 'VOID': case 'CANCELLED': color = AppColors.danger; label = 'Đã hủy'; break;
    default: color = AppColors.warning; label = 'Chưa thu';
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
  );
}

// ─── Main Screen ─────────────────────────────────────────────────────────────
class ManagerInvoicesScreen extends StatefulWidget {
  const ManagerInvoicesScreen({Key? key}) : super(key: key);
  @override State<ManagerInvoicesScreen> createState() => _ManagerInvoicesScreenState();
}

class _ManagerInvoicesScreenState extends State<ManagerInvoicesScreen> {
  List<InvoiceResult> _invoices = [];
  List<MotelResult> _motels = [];
  int? _selectedMotelId;
  bool _isLoading = true;
  String _selectedStatus = '';
  String _search = '';
  int _page = 0;
  int _totalPages = 0;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMotels();
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _loadMotels() async {
    try {
      final res = await MotelService.list(size: 50);
      if (mounted) { setState(() => _motels = res.content); }
    } catch (_) {}
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    try {
      final res = await InvoiceService.list(motelId: _selectedMotelId, status: _selectedStatus.isEmpty ? null : _selectedStatus, page: _page, size: 20);
      if (mounted) {
        setState(() {
          _invoices = res.content;
          _totalPages = res.totalPages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<InvoiceResult> get _filtered {
    if (_search.isEmpty) return _invoices;
    final q = _search.toLowerCase();
    return _invoices.where((inv) => '${inv.id}'.contains(q) || '${inv.roomId}'.contains(q) || (inv.roomNumber ?? '').toLowerCase().contains(q)).toList();
  }

  double get _totalAmount => _invoices.fold(0, (s, i) => s + (i.totalAmount));
  double get _paidAmount => _invoices.fold(0, (s, i) => s + (i.paidAmount ?? 0));
  double get _debtAmount => _totalAmount - _paidAmount;

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton(
        onPressed: _showGenerateSheet,
        backgroundColor: AppColors.primary,
        elevation: 2,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(children: [
        // Stats Bar
        if (!_isLoading) _buildStatsBar(),
        // Filters
        _buildFilters(),
        // List
        Expanded(child: RefreshIndicator(
          onRefresh: _loadInvoices,
          color: AppColors.primary,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
              : filtered.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                      itemCount: filtered.length + (_totalPages > 1 ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        if (i < filtered.length) return _buildCard(filtered[i]);
                        return _buildPager();
                      },
                    ),
        )),
      ]),
    );
  }

  Widget _buildStatsBar() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Row(children: [
      _statCard('Tổng dự kiến', _totalAmount, const Color(0xFF1E293B)),
      const SizedBox(width: 8),
      _statCard('Đã thu', _paidAmount, AppColors.success),
      const SizedBox(width: 8),
      _statCard('Còn nợ', _debtAmount, AppColors.danger, leftBorder: true),
    ]),
  );

  Widget _statCard(String label, double value, Color color, {bool leftBorder = false}) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('${_fmt(value)}đ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
      ]),
    ),
  );

  Widget _buildFilters() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
    child: Column(children: [
      // Search
      TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _search = v),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Tìm theo phòng, mã HĐ...',
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondaryLight),
          filled: true, fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      ),
      const SizedBox(height: 10),
      Row(children: [
        // Motel filter
        if (_motels.isNotEmpty) Expanded(child: _dropFilter<int?>(
          value: _selectedMotelId,
          hint: 'Tất cả khu trọ',
          items: [const DropdownMenuItem<int?>(value: null, child: Text('Tất cả khu trọ', style: TextStyle(fontSize: 12))), ..._motels.map((m) => DropdownMenuItem<int?>(value: m.id, child: Text(m.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)))],
          onChanged: (v) { setState(() { _selectedMotelId = v; _page = 0; }); _loadInvoices(); },
        )),
        if (_motels.isNotEmpty) const SizedBox(width: 8),
        // Status filter
        Expanded(child: _dropFilter<String>(
          value: _selectedStatus,
          hint: 'Trạng thái',
          items: [
            const DropdownMenuItem(value: '', child: Text('Tất cả', style: TextStyle(fontSize: 12))),
            const DropdownMenuItem(value: 'PENDING', child: Text('Chưa thu', style: TextStyle(fontSize: 12))),
            const DropdownMenuItem(value: 'PARTIAL', child: Text('Một phần', style: TextStyle(fontSize: 12))),
            const DropdownMenuItem(value: 'PAID', child: Text('Đã thu', style: TextStyle(fontSize: 12))),
            const DropdownMenuItem(value: 'VOID', child: Text('Đã hủy', style: TextStyle(fontSize: 12))),
          ],
          onChanged: (v) { setState(() { _selectedStatus = v ?? ''; _page = 0; }); _loadInvoices(); },
        )),
      ]),
    ]),
  );

  Widget _dropFilter<T>({required T value, required String hint, required List<DropdownMenuItem<T>> items, required void Function(T?) onChanged}) => Container(
    height: 38,
    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(10), color: Colors.white),
    child: DropdownButtonHideUnderline(child: DropdownButton<T>(
      isExpanded: true, value: value,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      borderRadius: BorderRadius.circular(10),
      style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
      items: items, onChanged: onChanged,
    )),
  );

  Widget _buildEmpty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 70, height: 70, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle), child: const Icon(Icons.receipt_long_outlined, size: 36, color: AppColors.primary)),
    const SizedBox(height: 16),
    const Text('Chưa có hóa đơn nào', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
    const SizedBox(height: 6),
    const Text('Nhấn + để xuất hóa đơn tháng này', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
    const SizedBox(height: 16),
    ElevatedButton.icon(onPressed: _showGenerateSheet, icon: const Icon(Icons.flash_on_rounded, size: 16), label: const Text('Tạo hóa đơn loạt'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
  ]));

  Widget _buildPager() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      OutlinedButton(onPressed: _page == 0 ? null : () { setState(() => _page--); _loadInvoices(); }, child: const Text('Trước')),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('${_page + 1} / $_totalPages', style: const TextStyle(fontSize: 13))),
      OutlinedButton(onPressed: _page >= _totalPages - 1 ? null : () { setState(() => _page++); _loadInvoices(); }, child: const Text('Sau')),
    ]),
  );

  Widget _buildCard(InvoiceResult inv) {
    final isPending = inv.status == 'PENDING' || inv.status == 'PARTIAL';
    return GestureDetector(
      onTap: () => _showDetailSheet(inv),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))]),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Row(children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(inv.roomNumber != null ? 'Phòng ${inv.roomNumber}' : 'Phòng ${inv.roomId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                  const SizedBox(width: 6),
                  Text('#${inv.id}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight, fontFamily: 'monospace')),
                ]),
                const SizedBox(height: 3),
                Text('${_fmtMonth(inv.billingMonth)}${inv.dueDate != null ? ' · Hạn: ${_fmtDate(inv.dueDate)}' : ''}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${_fmt(inv.totalAmount)}đ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                _statusBadge(inv.status),
              ]),
            ]),
            // Paid progress for PARTIAL
            if (inv.status == 'PARTIAL' && inv.totalAmount > 0) ...[
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: ((inv.paidAmount ?? 0) / inv.totalAmount).clamp(0, 1), minHeight: 5, backgroundColor: const Color(0xFFF1F5F9), valueColor: const AlwaysStoppedAnimation(AppColors.success)))),
                const SizedBox(width: 8),
                Text('Đã thu: ${_fmt(inv.paidAmount ?? 0)}đ', style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
              ]),
            ],
            // Action buttons for pending
            if (isPending) ...[
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                OutlinedButton.icon(
                  onPressed: () => _showPaymentSheet(inv),
                  icon: const Icon(Icons.credit_card_rounded, size: 14),
                  label: const Text('Thu tiền', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF059669), side: const BorderSide(color: Color(0xFF059669)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
              ]),
            ],
          ]),
        ),
      ),
    );
  }

  void _showDetailSheet(InvoiceResult inv) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6, maxChildSize: 0.9, minChildSize: 0.4,
        builder: (_, sc) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(children: [
            // Handle
            const SizedBox(height: 12),
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Expanded(child: SingleChildScrollView(controller: sc, padding: const EdgeInsets.fromLTRB(24, 0, 24, 32), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header
              Row(children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 24)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(inv.roomNumber != null ? 'Phòng ${inv.roomNumber}' : 'Phòng ${inv.roomId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('Mã HĐ #${inv.id}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight, fontFamily: 'monospace')),
                ])),
                _statusBadge(inv.status),
              ]),
              const SizedBox(height: 20),
              // Info grid
              _detailRow('Kỳ thanh toán', _fmtMonth(inv.billingMonth)),
              _detailRow('Hạn thanh toán', _fmtDate(inv.dueDate)),
              const Divider(height: 24),
              _detailRow('Tổng tiền', '${_fmt(inv.totalAmount)}đ', bold: true, color: const Color(0xFF1E293B)),
              _detailRow('Đã thu', '${_fmt(inv.paidAmount ?? 0)}đ', color: AppColors.success),
              _detailRow('Còn nợ', '${_fmt(inv.totalAmount - (inv.paidAmount ?? 0))}đ', color: inv.status == 'PAID' ? AppColors.success : AppColors.danger),
              if (inv.status == 'PARTIAL' && inv.totalAmount > 0) ...[
                const SizedBox(height: 10),
                ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: ((inv.paidAmount ?? 0) / inv.totalAmount).clamp(0, 1), minHeight: 8, backgroundColor: const Color(0xFFF1F5F9), valueColor: const AlwaysStoppedAnimation(AppColors.success))),
              ],
              const SizedBox(height: 20),
              // Action
              if (inv.status == 'PENDING' || inv.status == 'PARTIAL')
                SizedBox(width: double.infinity, child: ElevatedButton.icon(
                  onPressed: () { Navigator.pop(ctx); _showPaymentSheet(inv); },
                  icon: const Icon(Icons.credit_card_rounded),
                  label: const Text('Thu tiền', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                )),
              if (inv.status == 'PENDING' || inv.status == 'PARTIAL') const SizedBox(height: 10),
              if (inv.status != 'VOID' && inv.status != 'CANCELLED')
                SizedBox(width: double.infinity, child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final confirm = await showDialog<bool>(context: context, builder: (d) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Hủy hóa đơn', style: TextStyle(fontWeight: FontWeight.bold)),
                      content: const Text('Bạn có chắc muốn hủy hóa đơn này?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Không')),
                        ElevatedButton(onPressed: () => Navigator.pop(d, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Hủy HĐ')),
                      ],
                    ));
                    if (confirm == true) {
                      try { await InvoiceService.delete(inv.id); _loadInvoices(); _showSnack('Đã hủy hóa đơn.'); } catch (e) { _showSnack('Lỗi: $e'); }
                    }
                  },
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Hủy hóa đơn', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                )),
            ]))),
          ]),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool bold = false, Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight))),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.w600, color: color ?? const Color(0xFF1E293B))),
    ]),
  );

  void _showPaymentSheet(InvoiceResult inv) {
    final amountCtrl = TextEditingController(text: (inv.totalAmount - (inv.paidAmount ?? 0)).toStringAsFixed(0));
    String paymentMethod = 'CASH';

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF059669).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.credit_card_rounded, color: Color(0xFF059669), size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Thu tiền', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Phòng ${inv.roomNumber ?? inv.roomId} · #${inv.id}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
              ])),
            ]),
            const SizedBox(height: 20),
            // Amount
            const Text('Số tiền thu *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            TextField(
              controller: amountCtrl, keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                suffixText: 'đ', prefixIcon: const Icon(Icons.payments_outlined, size: 18, color: AppColors.textSecondaryLight),
                filled: true, fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
            ),
            const SizedBox(height: 16),
            // Payment method
            const Text('Phương thức *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            Row(children: [
              for (final m in [('CASH', Icons.money_rounded, 'Tiền mặt'), ('BANK_TRANSFER', Icons.account_balance_rounded, 'Chuyển khoản')]) ...[
                Expanded(child: GestureDetector(
                  onTap: () => setSheetState(() => paymentMethod = m.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: paymentMethod == m.$1 ? AppColors.primary.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: paymentMethod == m.$1 ? AppColors.primary : const Color(0xFFE2E8F0), width: paymentMethod == m.$1 ? 1.5 : 1),
                    ),
                    child: Column(children: [
                      Icon(m.$2, color: paymentMethod == m.$1 ? AppColors.primary : AppColors.textSecondaryLight, size: 20),
                      const SizedBox(height: 4),
                      Text(m.$3, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: paymentMethod == m.$1 ? AppColors.primary : AppColors.textSecondaryLight)),
                    ]),
                  ),
                )),
                if (m != ('BANK_TRANSFER', Icons.account_balance_rounded, 'Chuyển khoản')) const SizedBox(width: 10),
              ],
            ]),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0)))), child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600)))),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountCtrl.text);
                  if (amount == null || amount <= 0) { _showSnack('Số tiền không hợp lệ!'); return; }
                  Navigator.pop(ctx);
                  try {
                    await PaymentService.pay(invoiceId: inv.id, amount: amount, paymentMethod: paymentMethod);
                    _loadInvoices();
                    _showSnack('Đã thu tiền thành công!', success: true);
                  } catch (e) { _showSnack('Lỗi: $e'); }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Xác nhận thu tiền', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              )),
            ]),
          ]),
        ),
      )),
    );
  }

  void _showGenerateSheet() async {
    List<MotelResult> motels = _motels;
    if (motels.isEmpty) {
      try { final res = await MotelService.list(); motels = res.content; } catch (_) {}
    }
    if (!mounted) return;
    MotelResult? selected = motels.isNotEmpty ? motels.first : null;
    final now = DateTime.now();
    final monthCtrl = TextEditingController(text: '${now.year}-${now.month.toString().padLeft(2, '0')}');
    bool loading = false;
    bool success = false;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            if (success) ...[
              Center(child: Column(children: [
                Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.check_circle_outline_rounded, size: 48, color: AppColors.success)),
                const SizedBox(height: 12),
                const Text('Tạo hóa đơn thành công!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { Navigator.pop(ctx); _loadInvoices(); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('Xem danh sách hóa đơn', style: TextStyle(fontWeight: FontWeight.bold)))),
              ])),
            ] else ...[
              const Row(children: [
                Icon(Icons.flash_on_rounded, color: AppColors.primary, size: 24),
                SizedBox(width: 10),
                Text('Tạo hóa đơn loạt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ]),
              const SizedBox(height: 6),
              const Text('Hệ thống sẽ tự động tạo HĐ cho tất cả phòng đang có hợp đồng hoạt động.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
              const SizedBox(height: 20),
              if (motels.isNotEmpty) ...[
                const Text('Khu trọ *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                const SizedBox(height: 8),
                DropdownButtonFormField<MotelResult>(
                  value: selected, borderRadius: BorderRadius.circular(12),
                  decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF8FAFC), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0)))),
                  items: motels.map((m) => DropdownMenuItem(value: m, child: Text(m.name, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setS(() => selected = v),
                ),
                const SizedBox(height: 16),
              ],
              const Text('Kỳ hóa đơn (YYYY-MM) *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
              const SizedBox(height: 8),
              TextField(controller: monthCtrl, style: const TextStyle(fontSize: 14), decoration: InputDecoration(hintText: '2026-10', prefixIcon: const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.textSecondaryLight), filled: true, fillColor: const Color(0xFFF8FAFC), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)))),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0)))), child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600)))),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: ElevatedButton(
                  onPressed: loading ? null : () async {
                    if (selected == null || monthCtrl.text.trim().isEmpty) return;
                    setS(() => loading = true);
                    try {
                      await InvoiceService.generate(motelId: selected!.id, billingMonth: monthCtrl.text.trim());
                      setS(() { loading = false; success = true; });
                    } catch (e) {
                      setS(() => loading = false);
                      if (mounted) _showSnack('Lỗi: $e');
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Tạo hóa đơn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                )),
              ]),
            ],
          ]),
        ),
      )),
    );
  }

  void _showSnack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: success ? AppColors.success : null, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }
}
