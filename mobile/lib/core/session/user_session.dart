import 'package:flutter/foundation.dart';

/// Trạng thái phiên đăng nhập dùng chung giữa các màn hình.
class UserSession {
  /// Tên hiển thị hiện tại. Header lắng nghe để cập nhật ngay khi người dùng sửa hồ sơ.
  static final ValueNotifier<String?> displayName = ValueNotifier<String?>(null);
}
