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
}
