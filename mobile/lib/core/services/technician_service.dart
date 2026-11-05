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
}
