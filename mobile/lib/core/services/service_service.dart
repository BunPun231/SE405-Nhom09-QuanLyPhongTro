import '../network/api_client.dart';
import 'motel_service.dart';

class ServiceTierPricing {
  final double? tierStart;
  final double? tierEnd;
  final double pricePerUnit;

  ServiceTierPricing({
    this.tierStart,
    this.tierEnd,
    required this.pricePerUnit,
  });

  factory ServiceTierPricing.fromJson(Map<String, dynamic> json) {
    return ServiceTierPricing(
      tierStart: (json['tierStart'] as num?)?.toDouble(),
      tierEnd: (json['tierEnd'] as num?)?.toDouble(),
      pricePerUnit: (json['pricePerUnit'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    if (tierStart != null) 'tierStart': tierStart,
    if (tierEnd != null) 'tierEnd': tierEnd,
    'pricePerUnit': pricePerUnit,
  };
}

class ServiceResult {
  final int id;
  final int motelId;
  final String name;
  final String chargeType; // FIXED | METERED | PER_PERSON | PER_INDEX | PER_QUANTITY | TIERED
  final String? unit;
  final bool mandatory;
  final double? basePrice;
  final List<ServiceTierPricing>? pricingTiers;

  double get unitPrice => basePrice ?? 0;

  ServiceResult({
    required this.id,
    required this.motelId,
    required this.name,
    required this.chargeType,
    this.unit,
    this.mandatory = false,
    this.basePrice,
    this.pricingTiers,
  });

  factory ServiceResult.fromJson(Map<String, dynamic> json) {
    return ServiceResult(
      id: json['id'] ?? 0,
      motelId: json['motelId'] ?? 0,
      name: json['name'] ?? '',
      chargeType: json['chargeType'] ?? 'FIXED',
      unit: json['unit'],
      mandatory: json['mandatory'] ?? false,
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? (json['unitPrice'] as num?)?.toDouble(),
      pricingTiers: (json['pricingTiers'] as List<dynamic>?)
          ?.map((e) => ServiceTierPricing.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

typedef ServiceApiService = ServiceService;

class ServiceService {
  /// UC33: List services of a motel — GET /api/motels/{motelId}/services
  static Future<List<ServiceResult>> list(int motelId) async {
    final data = await ApiClient.get('/api/motels/$motelId/services', params: {'size': 100});
    if (data is List) {
      return data.map((e) => ServiceResult.fromJson(e as Map<String, dynamic>)).toList();
    } else if (data is Map && data.containsKey('content')) {
      return (data['content'] as List<dynamic>).map((e) => ServiceResult.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// UC34: Get service detail — GET /api/motels/{motelId}/services/{serviceId}
  static Future<ServiceResult> get(int motelId, int serviceId) async {
    final data = await ApiClient.get('/api/motels/$motelId/services/$serviceId');
    return ServiceResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC32: Create service — POST /api/motels/{motelId}/services
  static Future<ServiceResult> create(int motelId, Map<String, dynamic> body) async {
    final data = await ApiClient.post('/api/motels/$motelId/services', body: body);
    return ServiceResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC35: Update service — PATCH /api/motels/{motelId}/services/{serviceId}
  static Future<ServiceResult> update(int motelId, int serviceId, Map<String, dynamic> body) async {
    final data = await ApiClient.patch('/api/motels/$motelId/services/$serviceId', body: body);
    return ServiceResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC36: Delete service — DELETE /api/motels/{motelId}/services/{serviceId}
  static Future<void> delete(int motelId, int serviceId) async {
    await ApiClient.delete('/api/motels/$motelId/services/$serviceId');
  }

  /// UC37: Assign service to rooms — POST /api/motels/{motelId}/services/{serviceId}/assign-to-rooms
  static Future<void> assignToRooms(int motelId, int serviceId, List<int> roomIds) async {
    await ApiClient.post('/api/motels/$motelId/services/$serviceId/assign-to-rooms', body: {
      'roomIds': roomIds,
    });
  }

  /// List services assigned to a room — GET /api/motels/{motelId}/services/by-room/{roomId}
  static Future<List<ServiceResult>> listByRoom(int motelId, dynamic roomId) async {
    final data = await ApiClient.get('/api/motels/$motelId/services/by-room/$roomId');
    if (data is List) {
      return data.map((e) => ServiceResult.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
