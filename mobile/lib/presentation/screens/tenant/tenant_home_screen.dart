import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/contract_service.dart';
import '../../../core/services/invoice_service.dart';

class TenantHomeScreen extends StatefulWidget {
  final Function(int) onNavigateTab;

  const TenantHomeScreen({Key? key, required this.onNavigateTab}) : super(key: key);

  @override
  State<TenantHomeScreen> createState() => _TenantHomeScreenState();
}

class _TenantHomeScreenState extends State<TenantHomeScreen> {
  ContractResult? _contract;
  InvoiceResult? _unpaidInvoice;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTenantDashboard();
  }

  Future<void> _loadTenantDashboard() async {
    setState(() => _isLoading = true);
    try {
      final contracts = await ContractService.listActive();
      if (contracts.isNotEmpty) {
        _contract = contracts.first;
      }

      final invoices = await InvoiceService.listMine(status: 'UNPAID');
      if (invoices.content.isNotEmpty) {
        _unpaidInvoice = invoices.content.first;
      }
    } catch (e) {
      print('Error loading tenant home data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rentStr = _contract != null
        ? _contract!.rentPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')
        : '0';

    final invoiceAmountStr = _unpaidInvoice != null
        ? _unpaidInvoice!.totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')
        : '0';

    return RefreshIndicator(
      onRefresh: _loadTenantDashboard,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Room Hero Banner Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.verified_user_rounded, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    _contract != null ? 'Hợp đồng đang hiệu lực' : 'Chưa có hợp đồng',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Hạn: ${_contract?.endDate ?? 'N/A'}',
                              style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _contract != null ? 'Phòng #${_contract!.roomId}' : 'Chưa xếp phòng',
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Mã HĐ: ${_contract?.contractCode ?? 'N/A'}',
                          style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Color(0x3DFFFFFF), height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Tiền nhà hàng tháng', style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 11)),
                                Text('${rentStr}đ', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () => widget.onNavigateTab(3),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.25),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.description_rounded, size: 16),
                              label: const Text('Hợp đồng', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Active Unpaid Invoice Alert Banner
                  if (_unpaidInvoice != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Hóa đơn Tháng ${_unpaidInvoice!.billingMonth}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Hạn nộp: ${_unpaidInvoice!.dueDate ?? 'N/A'}',
                                            style: const TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${invoiceAmountStr}đ',
                                style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showVietQRDialog(context, _unpaidInvoice!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                              label: const Text('Thanh Toán Qua VietQR Ngay', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text('Bạn không có hóa đơn nào chờ thanh toán. Thật tuyệt vời!', style: TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Quick Action Grid
                  const Text('Thao Tác Nhanh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickCard(
                          icon: Icons.build_rounded,
                          title: 'Báo Sự Cố',
                          subtitle: 'Sửa vòi nước, bóng đèn',
                          color: AppColors.warning,
                          onTap: () => widget.onNavigateTab(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickCard(
                          icon: Icons.history_edu_rounded,
                          title: 'Lịch Sử Hóa Đơn',
                          subtitle: 'Xem hóa đơn cũ',
                          color: AppColors.success,
                          onTap: () => widget.onNavigateTab(1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  void _showVietQRDialog(BuildContext context, InvoiceResult invoice) {
    final amountStr = invoice.totalAmount.toStringAsFixed(0);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Mã VietQR Thanh Toán Tự Động', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Quét mã bằng ứng dụng Ngân hàng (MB, Vietcombank, Techcombank...)', style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Image.network(
                'https://img.vietqr.io/image/MB-99998888222-compact2.png?amount=$amountStr&addInfo=HOADON%20${invoice.id}&accountName=CHU%20TRO',
                height: 220,
                errorBuilder: (context, error, stackTrace) => Column(
                  children: [
                    const Icon(Icons.qr_code_scanner_rounded, size: 80, color: AppColors.primary),
                    const SizedBox(height: 8),
                    Text('STK: MB Bank 99998888222\nSố tiền: ${amountStr}đ\nNội dung: HOADON ${invoice.id}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Đã Chuyển Khoản / Đóng', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
          ],
        ),
      ),
    );
  }
}
