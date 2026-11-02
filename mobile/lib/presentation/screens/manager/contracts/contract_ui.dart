import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/contract_service.dart';

/// Token bổ sung theo DESIGN.md (chưa có trong AppColors): màu xác nhận tiền và
/// các sắc độ đậm cho chữ trạng thái cỡ nhỏ (đủ tương phản trên nền nhạt).
class ContractTokens {
  ContractTokens._();

  static const Color confirmGreen = Color(0xFF059669);
  static const Color greenText = Color(0xFF047857);
  static const Color amberText = Color(0xFFB45309);
  static const Color redText = Color(0xFFB91C1C);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color violetText = Color(0xFF6D28D9);
  static const Color slateText = Color(0xFF475569);
  static const Color heading = Color(0xFF1E293B);
  static const Color mist = Color(0xFFF1F5F9);
}

enum Tone { green, amber, red, violet, blue, slate }

extension ToneColors on Tone {
  Color get fg {
    switch (this) {
      case Tone.green:
        return ContractTokens.greenText;
      case Tone.amber:
        return ContractTokens.amberText;
      case Tone.red:
        return ContractTokens.redText;
      case Tone.violet:
        return ContractTokens.violetText;
      case Tone.blue:
        return AppColors.primaryDark;
      case Tone.slate:
        return ContractTokens.slateText;
    }
  }

  Color get base {
    switch (this) {
      case Tone.green:
        return AppColors.success;
      case Tone.amber:
        return AppColors.warning;
      case Tone.red:
        return AppColors.danger;
      case Tone.violet:
        return ContractTokens.violet;
      case Tone.blue:
        return AppColors.primary;
      case Tone.slate:
        return AppColors.textSecondaryLight;
    }
  }

  Color get bg => base.withValues(alpha: 0.10);
}

class Fmt {
  Fmt._();

  /// BR64.6: 3500000 → "3.500.000đ"
  static String vnd(num? value) {
    if (value == null) return '—';
    final negative = value < 0;
    final s = value.abs().round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${negative ? '-' : ''}$bufđ';
  }

  /// "2026-06-01" hoặc ISO datetime → "01/06/2026".
  static String date(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return dateOf(d);
  }

  static String dateOf(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String month(String? iso) {
    final d = iso == null ? null : DateTime.tryParse(iso);
    if (d == null) return iso ?? '—';
    return 'Tháng ${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  /// Parse số người dùng nhập ("3.500.000" hoặc "3500000").
  static double? parseMoney(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return double.tryParse(digits);
  }

  static String errorText(Object e) => e.toString().replaceFirst('Exception: ', '');
}

Tone contractTone(String status, String endDate) {
  if (ContractRules.isExpired(status, endDate)) return Tone.red;
  if (ContractRules.isExpiringSoon(status, endDate)) return Tone.amber;
  switch (status) {
    case 'ACTIVE':
      return Tone.green;
    case 'DRAFT':
      return Tone.violet;
    case 'PENDING_LIQUIDATION':
      return Tone.amber;
    case 'CANCELED':
    case 'CANCELLED':
      return Tone.red;
    default:
      return Tone.slate;
  }
}

String contractStatusText(String status, String endDate) {
  if (ContractRules.isExpired(status, endDate)) return 'Quá hạn';
  if (ContractRules.isExpiringSoon(status, endDate)) return 'Sắp hết hạn';
  return ContractRules.statusLabel(status);
}

Tone depositTone(String status) {
  switch (status) {
    case 'PAID':
      return Tone.green;
    case 'UNPAID':
      return Tone.amber;
    case 'REFUNDED':
      return Tone.slate;
    case 'DEDUCTED':
      return Tone.violet;
    default:
      return Tone.slate;
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Tone tone;
  const StatusBadge({super.key, required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: TextStyle(color: tone.fg, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  final Widget? trailing;
  const SectionCard({super.key, required this.title, required this.child, this.icon, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ContractTokens.heading),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;
  final Color? valueColor;
  const InfoRow({super.key, required this.label, required this.value, this.emphasize = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: emphasize ? 15 : 13,
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
                color: valueColor ?? ContractTokens.heading,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thanh tiến độ các bước cho luồng nhiều bước (tạo hợp đồng, tất toán).
class StepProgress extends StatelessWidget {
  final int current; // 0-based
  final List<String> titles;
  const StepProgress({super.key, required this.current, required this.titles});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bước ${current + 1}/${titles.length} · ${titles[current]}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ContractTokens.heading),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(titles.length, (i) {
              final done = i <= current;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i == titles.length - 1 ? 0 : 4),
                  decoration: BoxDecoration(
                    color: done ? AppColors.primary : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Thanh nút dưới cùng cho luồng nhiều bước. [confirm] = nút xanh lá chốt tiền.
class WizardBottomBar extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String nextLabel;
  final bool confirm;
  final bool loading;
  const WizardBottomBar({
    super.key,
    this.onBack,
    required this.onNext,
    required this.nextLabel,
    this.confirm = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.borderLight)),
        ),
        child: Row(
          children: [
            if (onBack != null) ...[
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: loading ? null : onBack,
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: const Text('Quay lại'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: loading ? null : onNext,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: confirm ? ContractTokens.confirmGreen : AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(nextLabel, textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ô thông báo nhỏ (gợi ý, cảnh báo, lỗi) theo quy tắc nền nhạt + chữ đậm cùng màu.
class NoticeBox extends StatelessWidget {
  final String text;
  final Tone tone;
  final IconData icon;
  const NoticeBox({super.key, required this.text, this.tone = Tone.blue, this.icon = Icons.info_outline_rounded});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: tone.fg),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: tone.fg, height: 1.35))),
        ],
      ),
    );
  }
}

/// Ô chọn ngày dạng nút (vùng chạm ≥ 48dp).
class DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final String? errorText;
  const DateField({super.key, required this.label, required this.value, required this.onTap, this.errorText});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
        ),
        child: Text(
          value == null ? 'Chọn ngày' : Fmt.dateOf(value!),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: value == null ? AppColors.textSecondaryLight : ContractTokens.heading,
          ),
        ),
      ),
    );
  }
}

Future<DateTime?> pickDate(BuildContext context, {DateTime? initial, DateTime? first, DateTime? last}) {
  final now = DateTime.now();
  final firstDate = first ?? DateTime(now.year - 5);
  final lastDate = last ?? DateTime(now.year + 10);
  var init = initial ?? now;
  if (init.isBefore(firstDate)) init = firstDate;
  if (init.isAfter(lastDate)) init = lastDate;
  return showDatePicker(
    context: context,
    initialDate: init,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: 'Chọn ngày',
    cancelText: 'Hủy',
    confirmText: 'Chọn',
  );
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? ContractTokens.redText : null,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
