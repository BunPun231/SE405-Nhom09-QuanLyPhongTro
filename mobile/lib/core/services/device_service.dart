import '../network/api_client.dart';
import 'motel_service.dart';

// ─── Types (mirror deviceService.ts / DeviceResult.java) ────────────────────

/// Nhãn hành động trong lịch sử biến động kho thiết bị.
const Map<String, String> kDeviceActionLabels = {
  'ASSIGN': 'Gán vào phòng',
  'RECALL': 'Thu hồi',
  'IMPORT': 'Nhập kho',
  'DISPOSE': 'Thanh lý',
  'MAINTENANCE_USE': 'Dùng cho bảo trì',
  'SEND_TO_REPAIR': 'Gửi sửa chữa',
  'FINISH_REPAIR': 'Sửa xong',
};

class DeviceResult {
  final int id;
  final int motelId;
  final String name;
  final String? brand;
  final double? purchasePrice;
  final String? purchaseDate;
  final int totalQuantity;
  final int inUseQuantity;
  final int repairingQuantity;
  final int availableQuantity;
  final String status; // IN_STOCK | IN_USE

  DeviceResult({
    required this.id,
    required this.motelId,
    required this.name,
    this.brand,
    this.purchasePrice,
    this.purchaseDate,
    required this.totalQuantity,
    required this.inUseQuantity,
    required this.repairingQuantity,
    required this.availableQuantity,
    required this.status,
  });

  factory DeviceResult.fromJson(Map<String, dynamic> json) {
    return DeviceResult(
      id: (json['id'] as num?)?.toInt() ?? 0,
      motelId: (json['motelId'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      brand: json['brand'],
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble(),
      purchaseDate: json['purchaseDate']?.toString(),
      totalQuantity: (json['totalQuantity'] as num?)?.toInt() ?? 0,
      inUseQuantity: (json['inUseQuantity'] as num?)?.toInt() ?? 0,
      repairingQuantity: (json['repairingQuantity'] as num?)?.toInt() ?? 0,
      availableQuantity: (json['availableQuantity'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'IN_STOCK',
    );
  }
}

class DeviceMovementLog {
  final int id;
  final int? fromRoomId;
  final int? toRoomId;
  final String action;
  final int quantity;
  final DateTime? timestamp;
  final String? note;

  DeviceMovementLog({
    required this.id,
    this.fromRoomId,
    this.toRoomId,
    required this.action,
    required this.quantity,
    this.timestamp,
    this.note,
  });

  String get actionLabel => kDeviceActionLabels[action] ?? action;

  factory DeviceMovementLog.fromJson(Map<String, dynamic> json) {
    return DeviceMovementLog(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fromRoomId: (json['fromRoomId'] as num?)?.toInt(),
      toRoomId: (json['toRoomId'] as num?)?.toInt(),
      action: json['action']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? ''),
      note: json['note'],
    );
  }
}

class DeviceUsage {
  final int id;
  final int deviceId;
  final String deviceName;
  final int roomId;
  final int assignedQuantity;
  final String? condition;

  DeviceUsage({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.roomId,
    required this.assignedQuantity,
    this.condition,
  });

  factory DeviceUsage.fromJson(Map<String, dynamic> json) {
    return DeviceUsage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      deviceId: (json['deviceId'] as num?)?.toInt() ?? 0,
      deviceName: json['deviceName']?.toString() ?? '',
      roomId: (json['roomId'] as num?)?.toInt() ?? 0,
      assignedQuantity: (json['assignedQuantity'] as num?)?.toInt() ?? 0,
      condition: json['condition'],
    );
  }
}

// ─── DeviceService ──────────────────────────────────────────────────────────

class DeviceService {
  /// UC41: Danh sách thiết bị của khu trọ — GET /api/motels/{motelId}/devices
  static Future<PageResponse<DeviceResult>> list(int motelId, {int page = 0, int size = 100}) async {
    final data = await ApiClient.get('/api/motels/$motelId/devices', params: {'page': page, 'size': size});
    return PageResponse.fromJson(data as Map<String, dynamic>, DeviceResult.fromJson);
  }

  /// Lịch sử biến động — GET /api/motels/{motelId}/devices/{id}/movement-logs
  static Future<List<DeviceMovementLog>> movementLogs(int motelId, int deviceId) async {
    final data = await ApiClient.get('/api/motels/$motelId/devices/$deviceId/movement-logs');
    return (data as List<dynamic>).map((e) => DeviceMovementLog.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String _base(int motelId) => '/api/motels/$motelId/devices';

  /// UC40: Thêm thiết bị mới — POST /api/motels/{motelId}/devices
  static Future<DeviceResult> create(
    int motelId, {
    required String name,
    String? brand,
    double? purchasePrice,
    String? purchaseDate, // yyyy-MM-dd
    int totalQuantity = 1,
  }) async {
    final data = await ApiClient.post(_base(motelId), body: {
      'name': name,
      if (brand != null && brand.isNotEmpty) 'brand': brand,
      if (purchasePrice != null) 'purchasePrice': purchasePrice,
      if (purchaseDate != null) 'purchaseDate': purchaseDate,
      'totalQuantity': totalQuantity,
    });
    return DeviceResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC44: Cập nhật thông tin — PATCH /api/motels/{motelId}/devices/{id}
  static Future<DeviceResult> update(
    int motelId,
    int deviceId, {
    String? name,
    String? brand,
    double? purchasePrice,
    String? purchaseDate,
  }) async {
    final data = await ApiClient.patch('${_base(motelId)}/$deviceId', body: {
      if (name != null) 'name': name,
      if (brand != null) 'brand': brand,
      if (purchasePrice != null) 'purchasePrice': purchasePrice,
      if (purchaseDate != null) 'purchaseDate': purchaseDate,
    });
    return DeviceResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC45: Xóa thiết bị khỏi danh mục — DELETE /api/motels/{motelId}/devices/{id}
  static Future<void> remove(int motelId, int deviceId) async {
    await ApiClient.delete('${_base(motelId)}/$deviceId');
  }

  /// Nhập thêm vào kho — POST .../import
  static Future<DeviceResult> importStock(int motelId, int deviceId, {required int quantity, String? note}) async {
    final data = await ApiClient.post('${_base(motelId)}/$deviceId/import', body: {'quantity': quantity, if (note != null && note.isNotEmpty) 'note': note});
    return DeviceResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC48: Thanh lý / hao hụt — POST .../dispose
  static Future<DeviceResult> dispose(int motelId, int deviceId, {required int quantity, String? reason}) async {
    final data = await ApiClient.post('${_base(motelId)}/$deviceId/dispose', body: {'quantity': quantity, if (reason != null && reason.isNotEmpty) 'reason': reason});
    return DeviceResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC46: Gán thiết bị vào phòng — POST .../assign
  static Future<void> assign(
    int motelId,
    int deviceId, {
    required int roomId,
    int quantity = 1,
    String? condition,
    String? note,
  }) async {
    await ApiClient.post('${_base(motelId)}/$deviceId/assign', body: {
      'roomId': roomId,
      'assignedQuantity': quantity,
      if (condition != null && condition.isNotEmpty) 'condition': condition,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  /// UC47: Thu hồi thiết bị từ phòng — POST .../recall?roomId=
  static Future<void> recall(int motelId, int deviceId, {required int roomId, int? quantity, String? note}) async {
    await ApiClient.post(
      '${_base(motelId)}/$deviceId/recall',
      params: {'roomId': roomId},
      body: {if (quantity != null) 'quantity': quantity, if (note != null && note.isNotEmpty) 'note': note},
    );
  }

  /// Gửi sửa chữa — POST .../send-to-repair
  static Future<DeviceResult> sendToRepair(int motelId, int deviceId, {required int quantity, String? note}) async {
    final data = await ApiClient.post('${_base(motelId)}/$deviceId/send-to-repair', body: {'quantity': quantity, if (note != null && note.isNotEmpty) 'note': note});
    return DeviceResult.fromJson(data as Map<String, dynamic>);
  }

  /// Sửa xong, nhập lại kho — POST .../finish-repair
  static Future<DeviceResult> finishRepair(int motelId, int deviceId, {required int quantity, String? note}) async {
    final data = await ApiClient.post('${_base(motelId)}/$deviceId/finish-repair', body: {'quantity': quantity, if (note != null && note.isNotEmpty) 'note': note});
    return DeviceResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC43: Thiết bị theo phòng — GET /api/motels/{motelId}/rooms/{roomId}/devices
  static Future<List<DeviceUsage>> byRoom(int motelId, int roomId) async {
    final data = await ApiClient.get('/api/motels/$motelId/rooms/$roomId/devices');
    return (data as List<dynamic>).map((e) => DeviceUsage.fromJson(e as Map<String, dynamic>)).toList();
  }
}
