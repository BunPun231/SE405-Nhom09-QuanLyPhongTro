import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../network/api_client.dart';
import 'motel_service.dart';

// ─── Types (mirror maintenanceService.ts / MaintenanceTicketResult.java) ─────

/// Danh mục sự cố — đúng với enum MaintenanceCategory của backend.
const Map<String, String> kMaintenanceCategories = {
  'ELECTRICITY': 'Điện',
  'WATER': 'Nước',
  'INTERNET': 'Internet',
  'HOUSE_STRUCTURE': 'Kết cấu nhà',
  'HOME_APPLIANCES': 'Đồ gia dụng',
  'OTHER': 'Khác',
};

/// Mức ưu tiên — đúng với enum MaintenancePriority của backend.
const Map<String, String> kMaintenancePriorities = {
  'LOW': 'Thấp',
  'MEDIUM': 'Trung bình',
  'HIGH': 'Cao',
  'URGENT': 'Khẩn cấp',
};

class MaintenanceDetailResult {
  final int id;
  final int? deviceId;
  final String? deviceName;
  final int quantityUsed;
  final List<String> afterImages;
  final String? note;

  MaintenanceDetailResult({
    required this.id,
    this.deviceId,
    this.deviceName,
    required this.quantityUsed,
    required this.afterImages,
    this.note,
  });

  factory MaintenanceDetailResult.fromJson(Map<String, dynamic> json) {
    return MaintenanceDetailResult(
      id: (json['id'] as num?)?.toInt() ?? 0,
      deviceId: (json['deviceId'] as num?)?.toInt(),
      deviceName: json['deviceName'],
      quantityUsed: (json['quantityUsed'] as num?)?.toInt() ?? 0,
      afterImages: (json['afterImages'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      note: json['note'],
    );
  }
}

class MaintenanceTicketResult {
  final int id;
  final int? motelId;
  final int roomId;
  final String roomNumber;
  final String? reporterName;
  final String? assignedTo;
  final String? technicianName;
  final String category;
  final String description;
  final List<String> beforeImages;
  final String status; // OPEN | PROCESSING | COMPLETED | ESCALATED | CANCELLED
  final String priority; // LOW | MEDIUM | HIGH | URGENT
  final List<MaintenanceDetailResult> details;
  final DateTime? createdAt;
  final DateTime? completedAt;

  MaintenanceTicketResult({
    required this.id,
    this.motelId,
    required this.roomId,
    required this.roomNumber,
    this.reporterName,
    this.assignedTo,
    this.technicianName,
    required this.category,
    required this.description,
    required this.beforeImages,
    required this.status,
    required this.priority,
    required this.details,
    this.createdAt,
    this.completedAt,
  });

  bool get isOpen => status == 'OPEN';
  bool get isProcessing => status == 'PROCESSING';
  bool get isCompleted => status == 'COMPLETED';
  bool get isCancelled => status == 'CANCELLED';
  bool get isAssigned => assignedTo != null && assignedTo!.isNotEmpty;
  String get categoryLabel => kMaintenanceCategories[category] ?? category;
  String get priorityLabel => kMaintenancePriorities[priority] ?? priority;

  factory MaintenanceTicketResult.fromJson(Map<String, dynamic> json) {
    return MaintenanceTicketResult(
      id: (json['id'] as num?)?.toInt() ?? 0,
      motelId: (json['motelId'] as num?)?.toInt(),
      roomId: (json['roomId'] as num?)?.toInt() ?? 0,
      roomNumber: json['roomNumber']?.toString() ?? '',
      reporterName: json['reporterName'],
      assignedTo: json['assignedTo']?.toString(),
      technicianName: json['technicianName'],
      category: json['category']?.toString() ?? 'OTHER',
      description: json['description']?.toString() ?? '',
      beforeImages: (json['beforeImages'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      status: json['status']?.toString() ?? 'OPEN',
      priority: json['priority']?.toString() ?? 'MEDIUM',
      details: (json['details'] as List<dynamic>? ?? [])
          .map((e) => MaintenanceDetailResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? ''),
    );
  }
}

// ─── MaintenanceService ─────────────────────────────────────────────────────

class MaintenanceService {
  static Future<List<http.MultipartFile>> _toMultipart(List<XFile> files) async {
    final result = <http.MultipartFile>[];
    for (final f in files) {
      result.add(http.MultipartFile.fromBytes('files', await f.readAsBytes(), filename: f.name));
    }
    return result;
  }

  static MaintenanceTicketResult _ticket(dynamic data) =>
      MaintenanceTicketResult.fromJson(data as Map<String, dynamic>);

  /// Backend trả phiếu cũ trước; đảo lại để phiếu mới nhất luôn nằm trên cùng.
  static PageResponse<MaintenanceTicketResult> _page(dynamic data) {
    final page = PageResponse.fromJson(data as Map<String, dynamic>, MaintenanceTicketResult.fromJson);
    final sorted = [...page.content]..sort((a, b) {
        final ta = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final tb = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return tb != ta ? tb.compareTo(ta) : b.id.compareTo(a.id);
      });
    return PageResponse(
      content: sorted,
      totalElements: page.totalElements,
      totalPages: page.totalPages,
      size: page.size,
      number: page.number,
    );
  }

  /// UC81: Tạo phiếu sự cố — POST /api/maintenance/tickets (multipart)
  static Future<MaintenanceTicketResult> createTicket({
    required int roomId,
    required String description,
    String category = 'OTHER',
    String priority = 'MEDIUM',
    List<XFile> photos = const [],
  }) async {
    final data = await ApiClient.postMultipart(
      '/api/maintenance/tickets',
      fields: {
        'roomId': roomId.toString(),
        'category': category,
        'description': description,
        'priority': priority,
      },
      files: await _toMultipart(photos),
    );
    return _ticket(data);
  }

  /// UC83: Chi tiết phiếu — GET /api/maintenance/tickets/{id}
  static Future<MaintenanceTicketResult> get(int ticketId) async {
    return _ticket(await ApiClient.get('/api/maintenance/tickets/$ticketId'));
  }

  /// UC82 (Tenant): phiếu tôi đã báo — GET /api/maintenance/my-tickets
  static Future<PageResponse<MaintenanceTicketResult>> listMine({int page = 0, int size = 50}) async {
    return _page(await ApiClient.get('/api/maintenance/my-tickets', params: {'page': page, 'size': size}));
  }

  /// UC82 (Manager): phiếu theo khu trọ — GET /api/maintenance/motels/{motelId}/tickets
  static Future<PageResponse<MaintenanceTicketResult>> listByMotel(int motelId, {int page = 0, int size = 50}) async {
    return _page(await ApiClient.get('/api/maintenance/motels/$motelId/tickets', params: {'page': page, 'size': size}));
  }

  /// UC82 (Technician): việc được giao — GET /api/maintenance/my-tasks
  static Future<PageResponse<MaintenanceTicketResult>> listMyTasks({int page = 0, int size = 50}) async {
    return _page(await ApiClient.get('/api/maintenance/my-tasks', params: {'page': page, 'size': size}));
  }

  /// UC84: Phân công KTV — POST /api/maintenance/tickets/{id}/assign
  static Future<MaintenanceTicketResult> assign(int ticketId, String technicianId) async {
    return _ticket(await ApiClient.post('/api/maintenance/tickets/$ticketId/assign', body: {'technicianId': technicianId}));
  }

  /// UC85: Hoàn thành — POST /api/maintenance/tickets/{id}/complete (multipart)
  static Future<MaintenanceTicketResult> complete(
    int ticketId, {
    String? note,
    int? usedDeviceId,
    int? usedQuantity,
    List<XFile> photos = const [],
  }) async {
    final data = await ApiClient.postMultipart(
      '/api/maintenance/tickets/$ticketId/complete',
      fields: {
        if (note != null && note.isNotEmpty) 'note': note,
        if (usedDeviceId != null) 'usedDeviceId': usedDeviceId.toString(),
        if (usedDeviceId != null) 'usedQuantity': (usedQuantity ?? 1).toString(),
      },
      files: await _toMultipart(photos),
    );
    return _ticket(data);
  }

  /// Hủy phiếu — POST /api/maintenance/tickets/{id}/cancel
  static Future<MaintenanceTicketResult> cancel(int ticketId) async {
    return _ticket(await ApiClient.post('/api/maintenance/tickets/$ticketId/cancel'));
  }

  /// Sửa phiếu — PUT /api/maintenance/tickets/{id}
  static Future<MaintenanceTicketResult> update(
    int ticketId, {
    String? category,
    String? description,
    String? priority,
  }) async {
    return _ticket(await ApiClient.put('/api/maintenance/tickets/$ticketId', body: {
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (priority != null) 'priority': priority,
    }));
  }
}
