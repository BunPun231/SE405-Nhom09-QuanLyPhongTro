import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/invoice_service.dart';

class TenantInvoicesScreen extends StatefulWidget {
  const TenantInvoicesScreen({Key? key}) : super(key: key);

  @override
  State<TenantInvoicesScreen> createState() => _TenantInvoicesScreenState();
}

class _TenantInvoicesScreenState extends State<TenantInvoicesScreen> {
  List<InvoiceResult> _invoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyInvoices();
  }

  Future<void> _loadMyInvoices() async {
    setState(() => _isLoading = true);
    try {
      final res = await InvoiceService.listMine();
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
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadMyInvoices,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _invoices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textSecondaryLight),
                        const SizedBox(height: 12),
                        const Text('Không có hóa đơn nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Text('Bạn đã hoàn thành thanh toán tất cả các khoản phí!', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _invoices.length,
                    itemBuilder: (context, index) {
                      return _buildInvoiceCard(_invoices[index]);
                    },
                  ),
      ),
    );
  }

  Widget _buildInvoiceCard(InvoiceResult inv) {
    final isPaid = inv.status == 'PAID';
    final amountStr = inv.totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isPaid ? AppColors.success : AppColors.danger).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isPaid ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
            color: isPaid ? AppColors.success : AppColors.danger,
          ),
        ),
        title: Text('Hóa đơn Tháng ${inv.billingMonth}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('Hạn nộp: ${inv.dueDate ?? 'Không có'}', style: const TextStyle(fontSize: 11)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${amountStr}đ', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (isPaid ? AppColors.success : AppColors.danger).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isPaid ? 'Đã Thanh Toán' : 'Chưa Thanh Toán',
                style: TextStyle(
                  color: isPaid ? AppColors.success : AppColors.danger,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
