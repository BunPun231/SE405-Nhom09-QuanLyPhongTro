import '../network/api_client.dart';
import 'motel_service.dart';

class ContractResult {
  final int id;
  final String? contractCode;
  final String tenantId;
  final int roomId;
  final String primaryResidentUserId;
  final String startDate;
  final String endDate;
  final double rentPrice;
  final double depositAmount;
  final String depositStatus; // UNPAID | PAID | REFUNDED | DEDUCTED | HOLDING | PENDING
  final String status; // ACTIVE | DRAFT | PENDING_LIQUIDATION | LIQUIDATED | CANCELED | CANCELLED
  final String? billingDate;
  final int? billingCycleDay;
  final int? paymentCycleMonths;
  final String? intendedMoveOutDate;
  final String? pdfUrl;
  final String? createdAt;
  final String? updatedAt;
  final String? notes;
  final List<String>? residentUserIds;

  ContractResult({
    required this.id,
    this.contractCode,
    required this.tenantId,
    required this.roomId,
    required this.primaryResidentUserId,
    required this.startDate,
    required this.endDate,
    required this.rentPrice,
    required this.depositAmount,
    required this.depositStatus,
    required this.status,
    this.billingDate,
    this.billingCycleDay,
    this.paymentCycleMonths,
    this.intendedMoveOutDate,
    this.pdfUrl,
    this.createdAt,
    this.updatedAt,
    this.notes,
    this.residentUserIds,
  });

  factory ContractResult.fromJson(Map<String, dynamic> json) {
    return ContractResult(
      id: json['id'] ?? 0,
      contractCode: json['contractCode'],
      tenantId: json['tenantId'] ?? '',
      roomId: json['roomId'] ?? 0,
      primaryResidentUserId: json['primaryResidentUserId'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      rentPrice: (json['rentPrice'] as num?)?.toDouble() ?? 0,
      depositAmount: (json['depositAmount'] as num?)?.toDouble() ?? 0,
      depositStatus: json['depositStatus'] ?? 'PENDING',
      status: json['status'] ?? 'ACTIVE',
      billingDate: json['billingDate'],
      billingCycleDay: json['billingCycleDay'],
      paymentCycleMonths: json['paymentCycleMonths'],
      intendedMoveOutDate: json['intendedMoveOutDate'],
      pdfUrl: json['pdfUrl'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      notes: json['notes'],
      residentUserIds: (json['residentUserIds'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );
  }
}

class ContractAppendixResult {
  final int id;
  final int contractId;
  final String type; // RENEW | PRICE_CHANGE | MOVE_OUT_NOTICE | MANUAL_CLAUSE
  final String? effectiveDate;
  final String? newEndDate;
  final double? newRentPrice;
  final String? intendedMoveOutDate;
  final String? metadata;
  final String createdAt;

  ContractAppendixResult({
    required this.id,
    required this.contractId,
    required this.type,
    this.effectiveDate,
    this.newEndDate,
    this.newRentPrice,
    this.intendedMoveOutDate,
    this.metadata,
    required this.createdAt,
  });

  factory ContractAppendixResult.fromJson(Map<String, dynamic> json) {
    return ContractAppendixResult(
      id: json['id'] ?? 0,
      contractId: json['contractId'] ?? 0,
      type: json['type'] ?? '',
      effectiveDate: json['effectiveDate'],
      newEndDate: json['newEndDate'],
      newRentPrice: (json['newRentPrice'] as num?)?.toDouble(),
      intendedMoveOutDate: json['intendedMoveOutDate'],
      metadata: json['metadata'],
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class ContractDetailResult {
  final int id;
  final String tenantId;
  final int roomId;
  final int? motelId;
  final String primaryResidentUserId;
  final double rentPrice;
  final String startDate;
  final String endDate;
  final double depositAmount;
  final String depositStatus;
  final String status;
  final String? billingDate;
  final int? billingCycleDay;
  final int? paymentCycleMonths;
  final String? intendedMoveOutDate;
  final String? pdfUrl;
  final String? createdAt;
  final List<String> residentUserIds;
  final int appendicesCount;

  ContractDetailResult({
    required this.id,
    required this.tenantId,
    required this.roomId,
    this.motelId,
    required this.primaryResidentUserId,
    required this.rentPrice,
    required this.startDate,
    required this.endDate,
    required this.depositAmount,
    required this.depositStatus,
    required this.status,
    this.billingDate,
    this.billingCycleDay,
    this.paymentCycleMonths,
    this.intendedMoveOutDate,
    this.pdfUrl,
    this.createdAt,
    required this.residentUserIds,
    this.appendicesCount = 0,
  });

  factory ContractDetailResult.fromJson(Map<String, dynamic> json) {
    return ContractDetailResult(
      id: json['id'] ?? 0,
      tenantId: json['tenantId'] ?? '',
      roomId: json['roomId'] ?? 0,
      motelId: json['motelId'],
      primaryResidentUserId: json['primaryResidentUserId'] ?? '',
      rentPrice: (json['rentPrice'] as num?)?.toDouble() ?? 0,
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      depositAmount: (json['depositAmount'] as num?)?.toDouble() ?? 0,
      depositStatus: json['depositStatus'] ?? 'PENDING',
      status: json['status'] ?? 'ACTIVE',
      billingDate: json['billingDate'],
      billingCycleDay: json['billingCycleDay'],
      paymentCycleMonths: json['paymentCycleMonths'],
      intendedMoveOutDate: json['intendedMoveOutDate'],
      pdfUrl: json['pdfUrl'],
      createdAt: json['createdAt'],
      residentUserIds: (json['residentUserIds'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      appendicesCount: json['appendicesCount'] ?? 0,
    );
  }
}

typedef ContractApiService = ContractService;

class ContractService {
  /// UC40: List all contracts for current tenant — GET /api/contracts
  static Future<List<ContractResult>> listAll() async {
    final data = await ApiClient.get('/api/contracts');
    if (data is List) {
      return data.map((e) => ContractResult.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// List contracts by Motel — GET /api/contracts/motels/{motelId}
  static Future<PageResponse<ContractResult>> listByMotel(
    int motelId, {
    String? status,
    bool expiring = false,
    int page = 0,
    int size = 20,
  }) async {
    final data = await ApiClient.get('/api/contracts/motels/$motelId', params: {
      if (status != null && status != 'ALL') 'status': status,
      if (expiring) 'expiring': true,
      'page': page,
      'size': size,
    });
    return PageResponse.fromJson(data as Map<String, dynamic>, ContractResult.fromJson);
  }

  /// List contracts with compatibility wrapper
  static Future<PageResponse<ContractResult>> list({int? roomId, String? status, int page = 0, int size = 50}) async {
    final data = await ApiClient.get('/api/contracts');
    if (data is List) {
      final all = data.map((e) => ContractResult.fromJson(e as Map<String, dynamic>)).toList();
      final filtered = all.where((c) {
        if (status != null && status != 'ALL' && c.status != status) return false;
        if (roomId != null && c.roomId != roomId) return false;
        return true;
      }).toList();
      return PageResponse(
        content: filtered,
        totalElements: filtered.length,
        totalPages: 1,
        size: size,
        number: page,
      );
    }
    return PageResponse(content: [], totalElements: 0, totalPages: 0, size: size, number: page);
  }

  /// List active contracts — GET /api/contracts/active (MANAGER/ADMIN)
  static Future<List<ContractResult>> listActive() async {
    final data = await ApiClient.get('/api/contracts/active');
    return (data as List<dynamic>).map((e) => ContractResult.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// List contracts of the current resident — GET /api/contracts/resident/{userId}
  static Future<List<ContractResult>> listMine({bool activeOnly = true}) async {
    final userId = ApiClient.userId;
    if (userId == null || userId.isEmpty) {
      throw Exception('Missing user session');
    }
    final data = await ApiClient.get('/api/contracts/resident/$userId');
    final contracts = (data as List<dynamic>)
        .map((e) => ContractResult.fromJson(e as Map<String, dynamic>))
        .toList();
    if (!activeOnly) return contracts;
    return contracts.where((c) => c.status.toUpperCase() == 'ACTIVE').toList();
  }

  /// Get contract summary by ID — GET /api/contracts/{id}
  static Future<ContractResult> get(int id) async {
    final data = await ApiClient.get('/api/contracts/$id');
    return ContractResult.fromJson(data as Map<String, dynamic>);
  }

  /// Get detailed contract by ID — GET /api/contracts/{id}/detail
  static Future<ContractDetailResult> getDetail(int id) async {
    final data = await ApiClient.get('/api/contracts/$id/detail');
    return ContractDetailResult.fromJson(data as Map<String, dynamic>);
  }

  /// Create contract — POST /api/contracts
  static Future<ContractResult> create(Map<String, dynamic> body) async {
    final data = await ApiClient.post('/api/contracts', body: body);
    return ContractResult.fromJson(data as Map<String, dynamic>);
  }

  /// Add appendix (Gia hạn, điều chỉnh giá, phụ lục) — POST /api/contracts/{id}/adjustments
  static Future<ContractAppendixResult> addAppendix(int contractId, Map<String, dynamic> body) async {
    final data = await ApiClient.post('/api/contracts/$contractId/adjustments', body: body);
    return ContractAppendixResult.fromJson(data as Map<String, dynamic>);
  }

  /// Collect deposit — POST /api/contracts/{id}/deposit/collect
  static Future<ContractResult> collectDeposit(int contractId) async {
    final data = await ApiClient.post('/api/contracts/$contractId/deposit/collect');
    return ContractResult.fromJson(data as Map<String, dynamic>);
  }

  /// Deduct deposit — POST /api/contracts/{id}/deposit/deduct
  static Future<void> deductDeposit(int contractId, {required double deductAmount, required String reason}) async {
    await ApiClient.post('/api/contracts/$contractId/deposit/deduct', body: {
      'deductAmount': deductAmount,
      'reason': reason,
    });
  }

  /// Refund deposit — POST /api/contracts/{id}/deposit/refund
  static Future<void> refundDeposit(int contractId, {String? notes}) async {
    await ApiClient.post('/api/contracts/$contractId/deposit/refund', body: {
      if (notes != null) 'notes': notes,
    });
  }

  /// Cancel contract — POST /api/contracts/{id}/cancel
  static Future<ContractResult> cancel(int contractId, {String? reason}) async {
    final data = await ApiClient.post(
      '/api/contracts/$contractId/cancel',
      params: reason != null ? {'reason': reason} : null,
    );
    return ContractResult.fromJson(data as Map<String, dynamic>);
  }

  /// Get appendices — GET /api/contracts/{id}/appendices
  static Future<PageResponse<ContractAppendixResult>> getAppendices(int contractId, {int page = 0, int size = 20}) async {
    final data = await ApiClient.get('/api/contracts/$contractId/appendices', params: {
      'page': page,
      'size': size,
    });
    return PageResponse.fromJson(data as Map<String, dynamic>, ContractAppendixResult.fromJson);
  }
}
