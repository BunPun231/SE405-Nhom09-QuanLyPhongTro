import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Hành vi cuộn chung cho toàn app:
/// - Cuộn đàn hồi mượt trên mọi nền tảng (Android, iOS, web).
/// - Cho phép kéo bằng chuột/trackpad như ngón tay khi xem thử trên Chrome.
/// - Luôn có thanh hiển thị vị trí đang cuộn (hiện khi cuộn, mờ dần khi dừng).
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  // Bỏ hiệu ứng "glow" xanh mặc định của Android vì đã có đệm đàn hồi.
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    // Chỉ gắn thanh cuộn cho danh sách cuộn dọc.
    if (details.direction != AxisDirection.down && details.direction != AxisDirection.up) {
      return child;
    }
    return ScrollbarTheme(
      data: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(4),
        radius: const Radius.circular(4),
        thumbColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.45)),
        crossAxisMargin: 2,
        minThumbLength: 36,
      ),
      child: Scrollbar(
        controller: details.controller,
        interactive: true,
        child: child,
      ),
    );
  }
}
