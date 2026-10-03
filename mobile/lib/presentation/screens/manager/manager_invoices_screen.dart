import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/invoice_service.dart';
import '../../../core/services/motel_service.dart';

class ManagerInvoicesScreen extends StatefulWidget {
  const ManagerInvoicesScreen({Key? key}) : super(key: key);

  @override
  State<ManagerInvoicesScreen> createState() => _ManagerInvoicesScreenState();
}

class _ManagerInvoicesScreenState extends State<ManagerInvoicesScreen> {
  List<InvoiceResult> _invoices = [];
  bool _isLoading = true;
  String _selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    try {
      final res = await InvoiceService.list();
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

  @override
  Widget build(BuildContext context) {
    final filtered = _invoices.where((inv) {
      if (_selectedStatus == 'ALL') return true;
      if (_selectedStatus == 'PAID') return inv.status == 'PAID';
      if (_selectedStatus == 'PENDING') return inv.status == 'PENDING' || inv.status == 'PARTIAL';
      if (_selectedStatus == 'VOID') return inv.status == 'VOID' || inv.status == 'CANCELLED';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton(
        onPressed: _showGenerateInvoiceSheet,
        backgroundColor: AppColors.primary,
        elevation: 2,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _filterChip('Tất cả (${_invoices.length})', 'ALL'),
                _filterChip('Chưa thu (${_invoices.where((i) => i.status == 'PENDING' || i.status == 'PARTIAL').length})', 'PENDING'),
                _filterChip('Đã thu (${_invoices.where((i) => i.status == 'PAID').length})', 'PAID'),
                _filterChip('Đã hủy (${_invoices.where((i) => i.status == 'VOID' || i.status == 'CANCELLED').length})', 'VOID'),
              ],
            ),
          ),

          // List of invoices
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadInvoices,
              color: AppColors.primary,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 70, height: 70,
                                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
                                child: const Icon(Icons.receipt_long_outlined, size: 36, color: AppColors.primary),
                              ),
                              const SizedBox(height: 16),
                              const Text('Chưa có hóa đơn nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              const SizedBox(height: 6),
                              const Text('Nhấn nút + bên dưới để xuất hóa đơn tháng này', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => _buildInvoiceCard(filtered[index]),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedStatus = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
            boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))] : [],
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(InvoiceResult inv) {
    Color color;
    String statusText;
    if (inv.status == 'PAID') {
      color = AppColors.success;
      statusText = 'Đã thu';
    } else if (inv.status == 'VOID' || inv.status == 'CANCELLED') {
      color = AppColors.danger;
      statusText = 'Đã hủy';
    } else {
      color = AppColors.warning;
      statusText = 'Chưa thu';
    }

    final amountStr = inv.totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.receipt_long_rounded, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Phòng ${inv.roomNumber ?? inv.roomId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                      const SizedBox(height: 3),
                      Text('Kỳ: ${inv.billingMonth} · Hạn: ${inv.dueDate ?? 'Không có'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$amountStrđ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(statusText, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showGenerateInvoiceSheet() async {
    List<MotelResult> motels = [];
    try {
      final motelRes = await MotelService.list();
      motels = motelRes.content;
    } catch (_) {}

    if (!mounted) return;

    final now = DateTime.now();
    final defaultMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final monthCtrl = TextEditingController(text: defaultMonth);
    MotelResult? selectedMotel = motels.isNotEmpty ? motels.first : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 24),
                    SizedBox(width: 10),
                    Text('Xuất Hóa Đơn Hàng Tháng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  ],
                ),
                const SizedBox(height: 20),

                if (motels.isNotEmpty) ...[
                  const Text('Chọn dãy trọ *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<MotelResult>(
                    value: selectedMotel,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    items: motels.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
                    onChanged: (val) => setSheetState(() => selectedMotel = val),
                  ),
                  const SizedBox(height: 16),
                ],

                const Text('Kỳ hóa đơn (YYYY-MM) *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                const SizedBox(height: 8),
                TextField(
                  controller: monthCtrl,
                  decoration: InputDecoration(
                    hintText: '2026-10',
                    prefixIcon: const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.textSecondaryLight),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (selectedMotel == null || monthCtrl.text.trim().isEmpty) return;
                          Navigator.pop(ctx);
                          try {
                            await InvoiceService.generate(
                              motelId: selectedMotel!.id,
                              billingMonth: monthCtrl.text.trim(),
                            );
                            _loadInvoices();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Đã xuất hóa đơn cho dãy trọ thành công!'),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xuất hóa đơn: $e')));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Xuất Hóa Đơn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
