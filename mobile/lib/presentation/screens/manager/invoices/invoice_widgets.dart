import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/invoice_service.dart';

/// Màu chữ trạng thái đậm, đủ tương phản trên nền nhạt (DESIGN.md: Tint-Not-Fill).
class InvoiceTones {
  static const Color ink = Color(0xFF0F172A);
  static const Color heading = Color(0xFF1E293B);
  static const Color muted = AppColors.textSecondaryLight;
  static const Color hairline = AppColors.borderLight;
  static const Color mist = Color(0xFFF1F5F9);
  static const Color paper = AppColors.backgroundLight;

  static const Color confirm = Color(0xFF059669); // nút chốt tiền
  static const Color paidText = Color(0xFF047857);
  static const Color pendingText = Color(0xFFB45309);
  static const Color partialText = Color(0xFFC2410C);
  static const Color dangerText = Color(0xFFB91C1C);
  static const Color voidText = Color(0xFF475569);

  static Color statusColor(String status) {
    switch (status) {
      case 'PAID':
        return paidText;
      case 'PARTIAL':
        return partialText;
      case 'VOID':
      case 'CANCELLED':
        return voidText;
      default:
        return pendingText;
    }
  }

  static Color statusTint(String status) {
    switch (status) {
      case 'PAID':
        return AppColors.success.withValues(alpha: 0.12);
      case 'PARTIAL':
        return const Color(0xFFF97316).withValues(alpha: 0.12);
      case 'VOID':
      case 'CANCELLED':
        return mist;
      default:
        return AppColors.warning.withValues(alpha: 0.14);
    }
  }
}

/// Nhãn trạng thái hóa đơn (BR74.3).
class InvoiceStatusBadge extends StatelessWidget {
  final String status;
  const InvoiceStatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: InvoiceTones.statusTint(status),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        invoiceStatusLabel(status),
        style: TextStyle(color: InvoiceTones.statusColor(status), fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Bộ ba số tiền: Tổng / Đã trả / Còn lại.
class InvoiceAmountTriple extends StatelessWidget {
  final double total;
  final double paid;
  final double remaining;
  final bool dense;

  const InvoiceAmountTriple({
    super.key,
    required this.total,
    required this.paid,
    required this.remaining,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, double value, Color color, CrossAxisAlignment align) => Expanded(
          child: Column(
            crossAxisAlignment: align,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: InvoiceTones.muted)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatVnd(value),
                  style: TextStyle(fontSize: dense ? 13 : 15, fontWeight: FontWeight.w800, color: color),
                ),
              ),
            ],
          ),
        );
    return Row(
      children: [
        cell('Tổng tiền', total, InvoiceTones.heading, CrossAxisAlignment.start),
        cell('Đã trả', paid, InvoiceTones.paidText, CrossAxisAlignment.center),
        cell('Còn lại', remaining, remaining > 0 ? InvoiceTones.dangerText : InvoiceTones.paidText, CrossAxisAlignment.end),
      ],
    );
  }
}

/// Thẻ tổng hợp ở đầu danh sách.
class InvoiceSummaryCard extends StatelessWidget {
  final InvoiceTotals totals;
  final String caption;

  const InvoiceSummaryCard({super.key, required this.totals, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: InvoiceTones.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(caption, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: InvoiceTones.muted)),
          const SizedBox(height: 8),
          InvoiceAmountTriple(total: totals.total, paid: totals.paid, remaining: totals.remaining),
        ],
      ),
    );
  }
}

/// Chip lọc dạng viên thuốc (DESIGN.md: chip-filter).
class InvoiceFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const InvoiceFilterChip({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: true,
      checkmarkColor: Colors.white,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : InvoiceTones.muted,
      ),
      side: BorderSide(color: selected ? AppColors.primary : InvoiceTones.hairline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}

/// Tay kéo + tiêu đề cho bottom sheet.
class SheetHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color iconColor;

  const SheetHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 44,
          height: 5,
          decoration: BoxDecoration(color: InvoiceTones.hairline, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: InvoiceTones.ink)),
                    if (subtitle != null)
                      Text(subtitle!, style: const TextStyle(fontSize: 12, color: InvoiceTones.muted)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Đóng',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: InvoiceTones.muted),
              ),
            ],
          ),
        ),
        const Divider(height: 16, thickness: 1, color: InvoiceTones.mist),
      ],
    );
  }
}

/// Khung trắng bo 28 cho bottom sheet, có lề bàn phím.
class SheetFrame extends StatelessWidget {
  final Widget child;
  final double maxHeightFactor;

  const SheetFrame({super.key, required this.child, this.maxHeightFactor = 0.92});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * maxHeightFactor),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(top: false, child: child),
        ),
      ),
    );
  }
}

/// Nhãn mục viết hoa nhỏ.
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: InvoiceTones.muted, letterSpacing: 0.4),
        ),
      );
}

/// Kiểu nút dùng chung.
class InvoiceButtonStyles {
  static ButtonStyle primary() => ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );

  static ButtonStyle confirm() => ElevatedButton.styleFrom(
        backgroundColor: InvoiceTones.confirm,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );

  static ButtonStyle outlined({Color foreground = InvoiceTones.ink}) => OutlinedButton.styleFrom(
        foregroundColor: foreground,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: const BorderSide(color: InvoiceTones.hairline),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );

  static ButtonStyle danger() => ElevatedButton.styleFrom(
        backgroundColor: AppColors.danger,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );
}

InputDecoration invoiceInputDecoration(String label, {String? hint, Widget? prefixIcon, String? suffixText}) {
  OutlineInputBorder border(Color c, [double w = 1]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c, width: w));
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefixIcon,
    suffixText: suffixText,
    isDense: false,
    filled: true,
    fillColor: Colors.white,
    labelStyle: const TextStyle(fontSize: 13, color: InvoiceTones.muted),
    hintStyle: const TextStyle(fontSize: 13, color: InvoiceTones.muted),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: border(InvoiceTones.hairline),
    enabledBorder: border(InvoiceTones.hairline),
    focusedBorder: border(AppColors.primary, 1.5),
  );
}

void showInvoiceSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? InvoiceTones.dangerText : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

String cleanError(Object e) => e.toString().replaceFirst('Exception: ', '');

/// Hộp chọn tháng (kỳ hóa đơn). Trả về ngày 1 của tháng được chọn, hoặc null nếu hủy.
Future<DateTime?> pickBillingMonth(BuildContext context, {DateTime? initial}) {
  final now = DateTime.now();
  var year = (initial ?? now).year;
  final selected = initial;
  return showDialog<DateTime>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: const Text('Chọn kỳ hóa đơn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'Năm trước',
                    onPressed: () => setLocal(() => year--),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Text('$year', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  IconButton(
                    tooltip: 'Năm sau',
                    onPressed: year >= now.year + 1 ? null : () => setLocal(() => year++),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.4,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(12, (i) {
                  final m = i + 1;
                  final isSel = selected != null && selected.year == year && selected.month == m;
                  return isSel
                      ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(ctx, DateTime(year, m)),
                          child: Text('T$m', style: const TextStyle(fontWeight: FontWeight.w700)),
                        )
                      : OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: InvoiceTones.heading,
                            side: const BorderSide(color: InvoiceTones.hairline),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(ctx, DateTime(year, m)),
                          child: Text('T$m'),
                        );
                }),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        ],
      ),
    ),
  );
}
