import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/invoice_service.dart';

String _fmt(double v) => formatVnd(v, withSymbol: false);

/// UC75 / BR75.6: Khối VietQR nhúng trong chi tiết hóa đơn chưa thanh toán xong.
/// Hiện mã QR động (số tiền = số còn nợ), số tài khoản và nội dung chuyển khoản.
class VietQrInlinePanel extends StatefulWidget {
  final int invoiceId;
  const VietQrInlinePanel({super.key, required this.invoiceId});

  @override
  State<VietQrInlinePanel> createState() => _VietQrInlinePanelState();
}

class _VietQrInlinePanelState extends State<VietQrInlinePanel> {
  InvoicePaymentInfoResult? _info;
  String? _error;
  bool _loading = true;

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
      final info = await InvoiceService.getPaymentInfo(widget.invoiceId);
      if (mounted) {
        setState(() {
          _info = info;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Đã sao chép $label'),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final box = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.borderLight),
    );
    if (_loading) {
      return Container(
        height: 120,
        decoration: box,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(strokeWidth: 2.5),
      );
    }
    if (_error != null || _info == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: box,
        child: Row(
          children: [
            const Icon(Icons.qr_code_2_rounded, color: AppColors.textSecondaryLight),
            const SizedBox(width: 10),
            Expanded(
              child: Text(_error ?? 'Chưa có thông tin thanh toán.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
            ),
            IconButton(tooltip: 'Tải lại mã QR', onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
          ],
        ),
      );
    }
    final info = _info!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: box,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              info.qrUrl,
              width: 128,
              height: 128,
              fit: BoxFit.contain,
              semanticLabel: 'Mã VietQR thanh toán hóa đơn #${widget.invoiceId}',
              errorBuilder: (_, __, ___) => Container(
                width: 128,
                height: 128,
                color: const Color(0xFFF1F5F9),
                child: const Icon(Icons.qr_code_2_rounded, size: 56, color: AppColors.textSecondaryLight),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Số tiền', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                Text('${_fmt(info.amount)}đ',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                const SizedBox(height: 4),
                Text('${info.bankName.isNotEmpty ? info.bankName : info.bankId} · ${info.bankAccount}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                Text(info.accountHolder.toUpperCase(),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                Row(
                  children: [
                    Expanded(
                      child: Text('Nội dung: ${info.memo}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'monospace', color: Color(0xFFB45309))),
                    ),
                    IconButton(
                      tooltip: 'Sao chép nội dung chuyển khoản',
                      onPressed: () => _copy(info.memo, 'nội dung chuyển khoản'),
                      icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VietQrPaymentSheet extends StatefulWidget {
  final int invoiceId;
  final VoidCallback? onSuccess;

  const VietQrPaymentSheet({
    super.key,
    required this.invoiceId,
    this.onSuccess,
  });

  static void show(BuildContext context, {required int invoiceId, VoidCallback? onSuccess}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VietQrPaymentSheet(
        invoiceId: invoiceId,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<VietQrPaymentSheet> createState() => _VietQrPaymentSheetState();
}

class _VietQrPaymentSheetState extends State<VietQrPaymentSheet> {
  bool _isLoading = true;
  String? _error;
  InvoicePaymentInfoResult? _paymentInfo;
  bool _isPaid = false;
  bool _isChecking = false;
  String? _copiedKey;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchPaymentInfo();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // Poll every 4 seconds to check if invoice has been paid
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!mounted || _isPaid) return;
      try {
        final inv = await InvoiceService.get(widget.invoiceId);
        if (!mounted) return;
        if (inv.status == 'PAID') {
          _pollingTimer?.cancel();
          setState(() => _isPaid = true);
          widget.onSuccess?.call();
        } else if (_paymentInfo != null && inv.remainingAmount.round() != _paymentInfo!.amount.round()) {
          // Nhận một phần tiền (UC78 - PARTIAL): tải lại mã QR với số còn nợ mới.
          widget.onSuccess?.call();
          _fetchPaymentInfo();
        }
      } catch (_) {}
    });
  }

  Future<void> _fetchPaymentInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final info = await InvoiceService.getPaymentInfo(widget.invoiceId);
      if (mounted) {
        setState(() {
          _paymentInfo = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkPaymentManual() async {
    setState(() => _isChecking = true);
    try {
      final inv = await InvoiceService.get(widget.invoiceId);
      if (inv.status == 'PAID') {
        _pollingTimer?.cancel();
        setState(() {
          _isPaid = true;
          _isChecking = false;
        });
        widget.onSuccess?.call();
      } else {
        setState(() => _isChecking = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chưa nhận đủ tiền (Đã trả: ${_fmt(inv.paidAmount)}đ / Còn lại: ${_fmt(inv.remainingAmount)}đ).'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChecking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể kiểm tra: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _copy(String text, String key, String label) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copiedKey = key);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label: $text'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _copiedKey == key) {
        setState(() => _copiedKey = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 14),

            // Sheet Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thanh toán hóa đơn #${widget.invoiceId}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                        ),
                        const Text(
                          'Tự động xác nhận khi ngân hàng báo có tiền',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
            ),
            const Divider(height: 20, thickness: 1, color: Color(0xFFF1F5F9)),

            // Content body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
            SizedBox(height: 16),
            Text(
              'Đang tạo mã thanh toán VietQR...',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.danger),
            ),
            const SizedBox(height: 14),
            const Text(
              'Không thể tải thông tin thanh toán',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 6),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Đóng'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _fetchPaymentInfo,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_isPaid) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.2), width: 3),
              ),
              child: const Icon(Icons.check_circle_rounded, size: 52, color: Color(0xFF059669)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Thanh Toán Thành Công!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 6),
            Text(
              'Hệ thống đã nhận được tiền chuyển khoản của bạn.\nHóa đơn #${widget.invoiceId} đã được chuyển sang trạng thái Đã thanh toán.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight, height: 1.4),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Số tiền đã nhận:', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                      Text('${_fmt(_paymentInfo?.amount ?? 0)}đ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Hình thức:', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                      Text('VietQR Auto Reconcile', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF059669))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onSuccess?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Hoàn tất / Đóng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      );
    }

    final info = _paymentInfo!;
    final amountFormatted = '${_fmt(info.amount)}đ';

    return Column(
      children: [
        // QR Image Container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.network(
                  info.qrUrl,
                  height: 200,
                  width: 200,
                  fit: BoxFit.contain,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(
                      height: 200,
                      width: 200,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  },
                  errorBuilder: (ctx, err, stack) => Container(
                    height: 200,
                    width: 200,
                    color: const Color(0xFFF1F5F9),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2_rounded, size: 64, color: AppColors.textSecondaryLight),
                        SizedBox(height: 8),
                        Text('Mã QR thanh toán', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Mở app Ngân hàng quét mã để thanh toán tự động',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Amount card
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SỐ TIỀN CẦN THANH TOÁN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight)),
                  const SizedBox(height: 2),
                  Text(amountFormatted, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
              TextButton.icon(
                onPressed: () => _copy(info.amount.toStringAsFixed(0), 'amount', 'Số tiền'),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                icon: Icon(
                  _copiedKey == 'amount' ? Icons.check_rounded : Icons.copy_rounded,
                  size: 16,
                  color: _copiedKey == 'amount' ? const Color(0xFF047857) : AppColors.primary,
                ),
                label: Text(
                  _copiedKey == 'amount' ? 'Đã chép' : 'Sao chép',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _copiedKey == 'amount' ? const Color(0xFF047857) : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Account Details Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _infoRow(label: 'Ngân hàng nhận', value: '${info.bankName} (${info.bankId})'),
              const Divider(height: 18, color: Color(0xFFF1F5F9)),
              _infoRow(
                label: 'Số tài khoản',
                value: info.bankAccount,
                mono: true,
                onCopy: () => _copy(info.bankAccount, 'account', 'Số tài khoản'),
                isCopied: _copiedKey == 'account',
              ),
              const Divider(height: 18, color: Color(0xFFF1F5F9)),
              _infoRow(label: 'Tên người nhận', value: info.accountHolder.toUpperCase(), bold: true),
              const Divider(height: 18, color: Color(0xFFF1F5F9)),
              _infoRow(
                label: 'Nội dung chuyển khoản',
                value: info.memo,
                mono: true,
                badge: true,
                onCopy: () => _copy(info.memo, 'memo', 'Nội dung chuyển khoản'),
                isCopied: _copiedKey == 'memo',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Warning Alert Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFB45309)),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: Color(0xFF92400E), height: 1.4),
                    children: [
                      const TextSpan(text: 'Quan trọng: Quý khách bắt buộc chuyển đúng số tiền và nội dung '),
                      TextSpan(text: info.memo, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                      const TextSpan(text: ' ở trên để hệ thống tự động ghi nhận thanh toán.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: const Text('Đóng', style: TextStyle(color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isChecking ? null : _checkPaymentManual,
                icon: _isChecking
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.sync_rounded, size: 18),
                label: Text(_isChecking ? 'Đang kiểm tra...' : 'Kiểm tra thanh toán', style: const TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoRow({
    required String label,
    required String value,
    bool mono = false,
    bool bold = false,
    bool badge = false,
    VoidCallback? onCopy,
    bool isCopied = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
        const SizedBox(width: 8),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badge)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontFamily: mono ? 'monospace' : null,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                )
              else
                Flexible(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: mono ? 'monospace' : null,
                      fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                      fontSize: 13,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
              if (onCopy != null) ...[
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Sao chép $label',
                  onPressed: onCopy,
                  icon: Icon(
                    isCopied ? Icons.check_rounded : Icons.copy_rounded,
                    size: 18,
                    color: isCopied ? const Color(0xFF047857) : AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
