import '../network/api_client.dart';

// ─── Types (mirror motelService.ts) ─────────────────────────────────────────

class PageResponse<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int size;
  final int number;

  PageResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.size,
    required this.number,
  });

  factory PageResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJson) {
    return PageResponse(
      content: (json['content'] as List<dynamic>? ?? []).map((e) => fromJson(e as Map<String, dynamic>)).toList(),
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      size: json['size'] ?? 20,
      number: json['number'] ?? 0,
    );
  }
}

class MotelResult {
  final int id;
  final String tenantId;
  final String name;
  final String address;
  final int totalFloors;
  final String? description;
  final String createdAt;
  final int? billingCycleDay;
  final double? depositPercent;

  MotelResult({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.address,
    required this.totalFloors,
    this.description,
    required this.createdAt,
    this.billingCycleDay,
    this.depositPercent,
  });

  factory MotelResult.fromJson(Map<String, dynamic> json) {
    return MotelResult(
      id: json['id'] ?? 0,
      tenantId: json['tenantId'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      totalFloors: json['totalFloors'] ?? 1,
      description: json['description'],
      createdAt: json['createdAt'] ?? '',
      billingCycleDay: json['billingCycleDay'],
      depositPercent: (json['depositPercent'] as num?)?.toDouble(),
    );
  }
}

class RoomResult {
  final int id;
  final String hashid;
  final int motelId;
  final String roomNumber;
  final int floor;
  final double? area;
  final double basePrice;
  final String status; // AVAILABLE | EMPTY | RENTED | DEPOSITED | REPAIRING | OUT_OF_BUSINESS
  final int currentResidentsCount;
  final String? description;

  RoomResult({
    required this.id,
    required this.hashid,
    required this.motelId,
    required this.roomNumber,
    required this.floor,
    this.area,
    required this.basePrice,
    required this.status,
    required this.currentResidentsCount,
    this.description,
  });

  factory RoomResult.fromJson(Map<String, dynamic> json) {
    return RoomResult(
      id: json['id'] ?? 0,
      hashid: json['hashid'] ?? '',
      motelId: json['motelId'] ?? 0,
      roomNumber: json['roomNumber'] ?? '',
      floor: json['floor'] ?? 1,
      area: (json['area'] as num?)?.toDouble(),
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0,
      status: json['status'] ?? 'AVAILABLE',
      currentResidentsCount: json['currentResidentsCount'] ?? 0,
      description: json['description'],
    );
  }
}

// ─── MotelService (mirror motelService.ts) ──────────────────────────────────

class MotelService {
  /// UC21: List motels — GET /api/motels
  static Future<PageResponse<MotelResult>> list({int page = 0, int size = 20}) async {
    final data = await ApiClient.get('/api/motels', params: {'page': page, 'size': size});
    return PageResponse.fromJson(data as Map<String, dynamic>, MotelResult.fromJson);
  }

  /// UC22: Get motel detail — GET /api/motels/{id}
  static Future<MotelResult> get(int id) async {
    final data = await ApiClient.get('/api/motels/$id');
    return MotelResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC20: Create motel — POST /api/motels
  static Future<MotelResult> create({
    required String name,
    required String address,
    required int totalFloors,
    String? description,
    int? billingCycleDay,
    double? depositPercent,
  }) async {
    final data = await ApiClient.post('/api/motels', body: {
      'name': name,
      'address': address,
      'totalFloors': totalFloors,
      if (description != null) 'description': description,
      if (billingCycleDay != null) 'billingCycleDay': billingCycleDay,
      if (depositPercent != null) 'depositPercent': depositPercent,
    });
    return MotelResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC23: Update motel — PATCH /api/motels/{id}
  static Future<MotelResult> update(int id, Map<String, dynamic> body) async {
    final data = await ApiClient.patch('/api/motels/$id', body: body);
    return MotelResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC25: Delete motel — DELETE /api/motels/{id}
  static Future<void> delete(int id) async {
    await ApiClient.delete('/api/motels/$id');
  }
}

// ─── RoomService (mirror roomService of motelService.ts) ───────────────────

class RoomService {
  /// UC27: List rooms — GET /api/motels/{motelId}/rooms
  static Future<PageResponse<RoomResult>> list(int motelId, {int page = 0, int size = 100}) async {
    final data = await ApiClient.get('/api/motels/$motelId/rooms', params: {'page': page, 'size': size});
    return PageResponse.fromJson(data as Map<String, dynamic>, RoomResult.fromJson);
  }

  /// UC28: Get room — GET /api/motels/{motelId}/rooms/{roomId}
  static Future<RoomResult> get(int motelId, dynamic roomId) async {
    final data = await ApiClient.get('/api/motels/$motelId/rooms/$roomId');
    return RoomResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC26: Create room — POST /api/motels/{motelId}/rooms
  static Future<RoomResult> create(int motelId, {
    required String roomNumber,
    required int floor,
    required double basePrice,
    double? area,
    String? description,
  }) async {
    final data = await ApiClient.post('/api/motels/$motelId/rooms', body: {
      'roomNumber': roomNumber,
      'floor': floor,
      'basePrice': basePrice,
      if (area != null) 'area': area,
      if (description != null) 'description': description,
    });
    return RoomResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC26+: Bulk create rooms — POST /api/motels/{motelId}/rooms/bulk
  static Future<List<RoomResult>> createBulk(int motelId, List<Map<String, dynamic>> rooms) async {
    final data = await ApiClient.post('/api/motels/$motelId/rooms/bulk', body: {
      'rooms': rooms,
    });
    return (data as List<dynamic>).map((e) => RoomResult.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// UC29: Update room — PATCH /api/motels/{motelId}/rooms/{roomId}
  static Future<RoomResult> update(int motelId, dynamic roomId, Map<String, dynamic> body) async {
    final data = await ApiClient.patch('/api/motels/$motelId/rooms/$roomId', body: body);
    return RoomResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC30: Change room status — PATCH /api/motels/{motelId}/rooms/{roomId}/status
  static Future<RoomResult> updateStatus(int motelId, dynamic roomId, String status, {String? reason}) async {
    final data = await ApiClient.patch('/api/motels/$motelId/rooms/$roomId/status', body: {
      'status': status,
      if (reason != null) 'reason': reason,
    });
    return RoomResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC31: Delete room — DELETE /api/motels/{motelId}/rooms/{roomId}
  static Future<void> delete(int motelId, dynamic roomId) async {
    await ApiClient.delete('/api/motels/$motelId/rooms/$roomId');
  }
}
