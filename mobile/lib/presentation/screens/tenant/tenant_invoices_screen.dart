import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/invoice_service.dart';
import '../../widgets/viet_qr_payment_sheet.dart';
import '../../widgets/invoice_detail_sheet.dart';

String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );

String _fmtMonth(String? raw) {
  if (raw == null || raw.isEmpty) return '-';
  try {
    final d = DateTime.parse(raw);
    return 'Tháng ${d.month}/${d.year}';
  } catch (_) {
    return raw.length >= 7 ? raw.substring(0, 7) : raw;
  }
}

String _fmtDate(String? raw) {
  if (raw == null || raw.isEmpty) return 'Không có';
  try {
    final d = DateTime.parse(raw);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  } catch (_) {
    return raw;
  }
}

class TenantInvoicesScreen extends StatefulWidget {
  const TenantInvoicesScreen({super.key});

  @override
  State<TenantInvoicesScreen> createState() => _TenantInvoicesScreenState();
}

class _TenantInvoicesScreenState extends State<TenantInvoicesScreen> {
  List<InvoiceResult> _invoices = [];
  bool _isLoading = true;
  String _selectedStatus = '';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMyInvoices();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMyInvoices() async {
    setState(() => _isLoading = true);
    try {
      final res = await InvoiceService.listMine(
        status: _selectedStatus.isEmpty ? null : _selectedStatus,
        size: 50,
      );
      if (mounted) {
        setState(() {
          _invoices = res.content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<InvoiceResult> get _filteredInvoices {
    if (_searchQuery.isEmpty) return _invoices;
    final q = _searchQuery.toLowerCase();
    return _invoices.where((inv) {
      return '${inv.id}'.contains(q) ||
          inv.billingMonth.toLowerCase().contains(q) ||
          (inv.roomNumber ?? '').toLowerCase().contains(q) ||
          '${inv.roomId}'.contains(q);
    }).toList();
  }

  double get _totalAmount => _invoices.fold(0, (sum, i) => sum + i.totalAmount);
  double get _paidAmount => _invoices.fold(0, (sum, i) => sum + i.paidAmount);
  double get _debtAmount => _totalAmount - _paidAmount;

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredInvoices;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header Stats
          if (!_isLoading) _buildStatsHeader(),

          // Filters & Search
          _buildFilterBar(),

          // List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadMyInvoices,
              color: AppColors.primary,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return _buildInvoiceCard(filtered[index]);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _buildStatCard('Tổng dự kiến', _totalAmount, const Color(0xFF1E293B)),
          const SizedBox(width: 8),
          _buildStatCard('Đã thanh toán', _paidAmount, const Color(0xFF059669)),
          const SizedBox(width: 8),
          _buildStatCard('Còn nợ', _debtAmount, AppColors.danger, isAlert: _debtAmount > 0),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, double value, Color color, {bool isAlert = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isAlert ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAlert ? const Color(0xFFFECACA) : const Color(0xFFF1F5F9),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              '${_fmt(value)}đ',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final statusTabs = [
      ('', 'Tất cả'),
      ('PENDING', 'Chưa thanh toán'),
      ('PARTIAL', 'Một phần'),
      ('PAID', 'Đã thanh toán'),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          // Search input
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Tìm theo mã HĐ, kỳ thanh toán...',
              hintStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondaryLight),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Horizontal Status Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: statusTabs.map((tab) {
                final isSelected = _selectedStatus == tab.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(tab.$2),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedStatus = tab.$1);
                        _loadMyInvoices();
                      }
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: const Color(0xFFF1F5F9),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_outlined, size: 54, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không tìm thấy hóa đơn nào',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Bạn đã thanh toán tất cả các khoản phí hoặc chưa có hóa đơn mới trong kỳ này.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight, height: 1.4),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _loadMyInvoices,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Làm mới danh sách'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(InvoiceResult inv) {
    final isPaid = inv.status == 'PAID';
    final isPending = inv.status == 'PENDING' || inv.status == 'PARTIAL';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPending ? const Color(0xFFCBD5E1) : const Color(0xFFF1F5F9),
          width: isPending ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openDetail(inv),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Room & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (isPaid ? const Color(0xFF059669) : AppColors.primary).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isPaid ? Icons.check_circle_rounded : Icons.receipt_long_rounded,
                              size: 18,
                              color: isPaid ? const Color(0xFF059669) : AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  inv.roomNumber != null ? 'Phòng P.${inv.roomNumber}' : 'Phòng ${inv.roomId}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Mã HĐ: #${inv.id}',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight, fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(inv.status),
                  ],
                ),
                const SizedBox(height: 12),

                // Middle info: Month & Due Date & Total Amount
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kỳ ${_fmtMonth(inv.billingMonth)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                          const SizedBox(height: 2),
                          Text('Hạn nộp: ${_fmtDate(inv.dueDate)}', style: TextStyle(fontSize: 11, color: isPending ? AppColors.danger : AppColors.textSecondaryLight)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Tổng tiền', style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
                          const SizedBox(height: 2),
                          Text(
                            '${_fmt(inv.totalAmount)}đ',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Partial progress bar if PARTIAL
                if (inv.status == 'PARTIAL' && inv.totalAmount > 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (inv.paidAmount / inv.totalAmount).clamp(0, 1),
                            minHeight: 5,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor: const AlwaysStoppedAnimation(Color(0xFF059669)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Đã trả: ${_fmt(inv.paidAmount)}đ',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // Bottom Action Buttons
                Row(
                  children: [
                    // View detail button
                    OutlinedButton.icon(
                      onPressed: () => _openDetail(inv),
                      icon: const Icon(Icons.visibility_outlined, size: 15),
                      label: const Text('Chi tiết', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Pay VietQR Button (for PENDING or PARTIAL)
                    if (isPending)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openPayment(inv),
                          icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                          label: const Text(
                            'Thanh toán VietQR ➜',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            elevation: 0,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      )
                    else ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF059669)),
                            SizedBox(width: 4),
                            Text('Đã hoàn tất', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF059669))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDetail(InvoiceResult inv) {
    InvoiceDetailSheet.show(
      context,
      invoiceId: inv.id,
      initialInvoice: inv,
      onPaymentSuccess: _loadMyInvoices,
    );
  }

  void _openPayment(InvoiceResult inv) {
    VietQrPaymentSheet.show(
      context,
      invoiceId: inv.id,
      onSuccess: _loadMyInvoices,
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'PAID':
        color = const Color(0xFF059669);
        label = 'Đã thanh toán';
        break;
      case 'PARTIAL':
        color = const Color(0xFF0284C7);
        label = 'Một phần';
        break;
      case 'VOID':
      case 'CANCELLED':
        color = AppColors.danger;
        label = 'Đã hủy';
        break;
      default:
        color = const Color(0xFFD97706);
        label = 'Chưa thanh toán';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
