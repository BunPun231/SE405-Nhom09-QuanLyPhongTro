import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/meter_reading_service.dart';

/// Màu chữ trạng thái cỡ nhỏ: đậm hơn token để đủ tương phản trên nền nhạt.
class MeterTone {
  MeterTone._();
  static const Color successText = Color(0xFF047857);
  static const Color warningText = Color(0xFFB45309);
  static const Color dangerText = Color(0xFFB91C1C);
  static const Color confirm = Color(0xFF059669);
  static const Color heading = Color(0xFF1E293B);
  static const Color mist = Color(0xFFF1F5F9);

  static Color statusFill(String? status) {
    switch (status) {
      case MeterStatus.approved:
        return AppColors.success;
      case MeterStatus.rejected:
        return AppColors.danger;
      case MeterStatus.pending:
      case 'SUBMITTED':
        return AppColors.warning;
      default:
        return AppColors.textSecondaryLight;
    }
  }

  static Color statusText(String? status) {
    switch (status) {
      case MeterStatus.approved:
        return successText;
      case MeterStatus.rejected:
        return dangerText;
      case MeterStatus.pending:
      case 'SUBMITTED':
        return warningText;
      default:
        return AppColors.textSecondaryLight;
    }
  }
}

/// Nhãn trạng thái (nền 10%, chữ đậm cùng sắc).
class MeterStatusBadge extends StatelessWidget {
  final String? status;
  const MeterStatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: MeterTone.statusFill(status).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        MeterStatus.label(status),
        style: TextStyle(
          color: MeterTone.statusText(status),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Ô biểu tượng điện/nước 44×44.
class MeterServiceIcon extends StatelessWidget {
  final String serviceName;
  final double size;
  const MeterServiceIcon(this.serviceName, {super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final electric = MeterRules.isElectric(serviceName);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        electric ? Icons.bolt_rounded : Icons.water_drop_rounded,
        color: AppColors.primary,
        size: size * 0.5,
      ),
    );
  }
}

/// Một cột số: nhãn nhỏ xám + con số lớn đậm.
class MeterNumber extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final double fontSize;
  const MeterNumber({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: color ?? MeterTone.heading,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

/// Hàng 3 số: cũ → mới → tiêu thụ.
class MeterNumbersRow extends StatelessWidget {
  final double? oldReading;
  final double? newReading;
  final double? consumption;
  final String? unit;
  final bool highlightConsumption;
  const MeterNumbersRow({
    super.key,
    this.oldReading,
    this.newReading,
    this.consumption,
    this.unit,
    this.highlightConsumption = false,
  });

  @override
  Widget build(BuildContext context) {
    final u = (unit == null || unit!.isEmpty) ? '' : ' $unit';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: MeterNumber(label: 'Chỉ số cũ', value: MeterRules.formatReading(oldReading))),
          Expanded(
            child: MeterNumber(
              label: 'Chỉ số mới',
              value: newReading == null ? 'Chưa ghi' : MeterRules.formatReading(newReading),
              color: newReading == null ? AppColors.textSecondaryLight : null,
            ),
          ),
          Expanded(
            child: MeterNumber(
              label: 'Tiêu thụ',
              value: consumption == null ? '—' : '${MeterRules.formatReading(consumption)}$u',
              color: highlightConsumption ? MeterTone.dangerText : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ảnh đồng hồ thu nhỏ; chạm để phóng to (BR72.5).
class MeterImageThumb extends StatelessWidget {
  final String? url;
  final double size;
  const MeterImageThumb({super.key, required this.url, this.size = 64});

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: MeterTone.mist,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Tooltip(
          message: 'Không có ảnh đồng hồ',
          child: Icon(Icons.hide_image_outlined, color: AppColors.textSecondaryLight),
        ),
      );
    }
    return Material(
      color: MeterTone.mist,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showMeterImage(context, url!),
        child: Tooltip(
          message: 'Xem ảnh đồng hồ',
          child: SizedBox(
            width: size,
            height: size,
            child: Image.network(
              url!,
              fit: BoxFit.cover,
              cacheWidth: (size * 3).round(),
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image_outlined, color: AppColors.textSecondaryLight),
              loadingBuilder: (c, child, p) => p == null
                  ? child
                  : const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hộp thoại xem ảnh đồng hồ phóng to (có thể kéo/zoom).
Future<void> showMeterImage(BuildContext context, String url, {String title = 'Ảnh đồng hồ'}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                IconButton(
                  tooltip: 'Đóng',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
          Flexible(
            child: InteractiveViewer(
              maxScale: 5,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Không tải được ảnh', style: TextStyle(color: AppColors.textSecondaryLight)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

/// Khung thông báo có màu theo nghĩa (cảnh báo / lỗi / thành công / thông tin).
class MeterNotice extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color fill;
  final Color ink;
  final Widget? trailing;
  const MeterNotice({
    super.key,
    required this.icon,
    required this.text,
    required this.fill,
    required this.ink,
    this.trailing,
  });

  factory MeterNotice.warning(String text, {Widget? trailing}) => MeterNotice(
        icon: Icons.warning_amber_rounded,
        text: text,
        fill: AppColors.warning,
        ink: MeterTone.warningText,
        trailing: trailing,
      );

  factory MeterNotice.danger(String text, {Widget? trailing}) => MeterNotice(
        icon: Icons.error_outline_rounded,
        text: text,
        fill: AppColors.danger,
        ink: MeterTone.dangerText,
        trailing: trailing,
      );

  factory MeterNotice.success(String text, {Widget? trailing}) => MeterNotice(
        icon: Icons.check_circle_outline_rounded,
        text: text,
        fill: AppColors.success,
        ink: MeterTone.successText,
        trailing: trailing,
      );

  factory MeterNotice.info(String text) => MeterNotice(
        icon: Icons.info_outline_rounded,
        text: text,
        fill: AppColors.primary,
        ink: AppColors.primaryDark,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fill.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: ink),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, color: ink, fontWeight: FontWeight.w600, height: 1.35)),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

/// Nút chọn tháng (vùng chạm 48dp).
class MeterMonthButton extends StatelessWidget {
  final String monthKey;
  final VoidCallback onPressed;
  const MeterMonthButton({super.key, required this.monthKey, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.calendar_month_rounded, size: 18),
      label: Text(MeterRules.monthLabel(monthKey)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        foregroundColor: AppColors.textPrimaryLight,
        side: const BorderSide(color: AppColors.borderLight),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

/// Hộp thoại chọn tháng/năm. Trả về khóa `yyyy-MM`.
Future<String?> pickMeterMonth(BuildContext context, String currentKey) {
  final parts = currentKey.split('-');
  var year = int.tryParse(parts.first) ?? DateTime.now().year;
  final selectedMonth = parts.length > 1 ? int.tryParse(parts[1]) ?? 1 : 1;
  final selectedYear = year;
  final now = DateTime.now();
  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        title: Row(
          children: [
            IconButton(
              tooltip: 'Năm trước',
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () => setLocal(() => year--),
            ),
            Expanded(
              child: Text('Năm $year',
                  textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            ),
            IconButton(
              tooltip: 'Năm sau',
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: year >= now.year ? null : () => setLocal(() => year++),
            ),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.9,
            children: List.generate(12, (i) {
              final m = i + 1;
              final selected = m == selectedMonth && year == selectedYear;
              final future = year == now.year && m > now.month;
              final key = '$year-${m.toString().padLeft(2, '0')}';
              return selected
                  ? FilledButton(
                      onPressed: () => Navigator.pop(ctx, key),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('T$m', style: const TextStyle(fontWeight: FontWeight.w700)),
                    )
                  : OutlinedButton(
                      onPressed: future ? null : () => Navigator.pop(ctx, key),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: AppColors.textPrimaryLight,
                        side: const BorderSide(color: AppColors.borderLight),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('T$m'),
                    );
            }),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        ],
      ),
    ),
  );
}

/// Trạng thái rỗng / lỗi dùng chung.
class MeterEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const MeterEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: MeterTone.heading)),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(minimumSize: const Size(120, 48)),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String meterErrorText(Object e) => e.toString().replaceFirst('Exception: ', '');
