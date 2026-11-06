import '../network/api_client.dart';
import 'motel_service.dart';

// ─── Types (mirror adminService.ts / ManagerResponse.java) ──────────────────

class ManagerResult {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String status; // ACTIVE | LOCKED | PENDING_VERIFICATION
  final String? tenantName;
  final DateTime? createdAt;
  final String? lockReason;

  ManagerResult({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    required this.status,
    this.tenantName,
    this.createdAt,
    this.lockReason,
  });

  bool get locked => status == 'LOCKED';

  factory ManagerResult.fromJson(Map<String, dynamic> json) {
    return ManagerResult(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email'],
      phone: json['phone'],
      status: json['status']?.toString() ?? 'ACTIVE',
      tenantName: json['tenantName'],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      lockReason: json['lockReason'],
    );
  }
}

// ─── AdminService ───────────────────────────────────────────────────────────

class AdminService {
  /// UC09: Danh sách chủ trọ — GET /api/v1/admin/managers
  static Future<PageResponse<ManagerResult>> getManagers({
    String? search,
    String? status,
    int page = 0,
    int size = 20,
  }) async {
    final data = await ApiClient.get('/api/v1/admin/managers', params: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
      'page': page,
      'size': size,
    });
    return PageResponse.fromJson(data as Map<String, dynamic>, ManagerResult.fromJson);
  }

  /// UC10: Khóa / mở khóa tài khoản chủ trọ — PATCH /api/v1/admin/managers/{id}/status
  static Future<void> updateStatus(String id, {required bool lock, String? reason}) async {
    await ApiClient.patch('/api/v1/admin/managers/$id/status', body: {
      'status': lock ? 'LOCKED' : 'ACTIVE',
      if (lock && reason != null && reason.isNotEmpty) 'lockReason': reason,
    });
  }
}
