import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../session/user_session.dart';

// ─── Types (mirror userService.ts / UserProfileResponse.java) ───────────────

class UserProfile {
  final String id;
  final String phone;
  final String? email;
  final String fullName;
  final String? avatarUrl;
  final String role;
  final String status;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  UserProfile({
    required this.id,
    required this.phone,
    this.email,
    required this.fullName,
    this.avatarUrl,
    required this.role,
    required this.status,
    this.createdAt,
    this.lastLoginAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email'],
      fullName: json['fullName']?.toString() ?? '',
      avatarUrl: json['avatarUrl'],
      role: json['role']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      lastLoginAt: DateTime.tryParse(json['lastLoginAt']?.toString() ?? ''),
    );
  }
}

// ─── UserService ────────────────────────────────────────────────────────────

class UserService {
  /// UC03: Xem profile cá nhân — GET /api/v1/users/profile
  static Future<UserProfile> getProfile() async {
    final data = await ApiClient.get('/api/v1/users/profile');
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  /// UC04: Cập nhật profile — PUT /api/v1/users/profile
  static Future<UserProfile> updateProfile({
    required String fullName,
    String? email,
    String? phone,
  }) async {
    final data = await ApiClient.put('/api/v1/users/profile', body: {
      'fullName': fullName,
      if (email != null && email.isNotEmpty) 'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    final profile = UserProfile.fromJson(data as Map<String, dynamic>);
    // Đồng bộ tên hiển thị (header, lần mở app sau).
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_fullname', profile.fullName);
    UserSession.displayName.value = profile.fullName;
    return profile;
  }
}
