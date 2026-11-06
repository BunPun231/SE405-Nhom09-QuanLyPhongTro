import '../network/api_client.dart';
import 'motel_service.dart';

// ─── Types (mirror technicianService.ts / TechnicianResult.java) ────────────

class TechnicianResult {
  final String userId;
  final String phone;
  final String? email;
  final String fullName;
  final String status; // ACTIVE | LOCKED | PENDING | INACTIVE
  final List<String> expertise;
  final bool available;
  final List<int> assignedMotelIds;

  TechnicianResult({
    required this.userId,
    required this.phone,
    this.email,
    required this.fullName,
    required this.status,
    required this.expertise,
    required this.available,
    required this.assignedMotelIds,
  });

  bool get locked => status == 'LOCKED';

  factory TechnicianResult.fromJson(Map<String, dynamic> json) {
    return TechnicianResult(
      userId: (json['userId'] ?? json['id'] ?? '').toString(),
      phone: json['phone']?.toString() ?? '',
      email: json['email'],
      fullName: json['fullName']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACTIVE',
      expertise: (json['expertise'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      available: json['available'] ?? true,
      assignedMotelIds: (json['assignedMotelIds'] as List<dynamic>? ?? []).map((e) => (e as num).toInt()).toList(),
    );
  }
}

// ─── TechnicianService ──────────────────────────────────────────────────────

class TechnicianService {
  /// UC57: Danh sách KTV — GET /api/technicians
  static Future<PageResponse<TechnicianResult>> list({int page = 0, int size = 100}) async {
    final data = await ApiClient.get('/api/technicians', params: {'page': page, 'size': size});
    return PageResponse.fromJson(data as Map<String, dynamic>, TechnicianResult.fromJson);
  }

  /// UC56/61: Thêm KTV (tự cấp tài khoản, mật khẩu mặc định là SĐT) — POST /api/technicians
  static Future<TechnicianResult> create({
    required String phone,
    required String fullName,
    String? email,
    List<String> expertise = const [],
    List<int> assignedMotelIds = const [],
  }) async {
    final data = await ApiClient.post('/api/technicians', body: {
      'phone': phone,
      'fullName': fullName,
      if (email != null && email.isNotEmpty) 'email': email,
      'expertise': expertise,
      'assignedMotelIds': assignedMotelIds,
    });
    return TechnicianResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC60: Khóa tài khoản KTV — POST /api/technicians/{id}/lock
  static Future<void> lock(String techId, {String? reason}) async {
    await ApiClient.post('/api/technicians/$techId/lock', body: {if (reason != null && reason.isNotEmpty) 'reason': reason});
  }

  /// UC62: Reset mật khẩu KTV về mặc định (SĐT) — POST /api/technicians/{id}/reset-password
  static Future<void> resetPassword(String techId) async {
    await ApiClient.post('/api/technicians/$techId/reset-password');
  }
}
