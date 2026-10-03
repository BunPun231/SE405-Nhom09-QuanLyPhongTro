import '../network/api_client.dart';
import 'motel_service.dart';

// ─── Types (mirror invoiceService.ts) ─────────────────────────────────────────

class InvoiceDetail {
  final int id;
  final int serviceId;
  final String serviceName;
  final String chargeType;
  final double? oldReading;
  final double? newReading;
  final double? consumption;
  final double unitPrice;
  final double totalCost;

  InvoiceDetail({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.chargeType,
    this.oldReading,
    this.newReading,
    this.consumption,
    required this.unitPrice,
    required this.totalCost,
  });

  factory InvoiceDetail.fromJson(Map<String, dynamic> json) {
    return InvoiceDetail(
      id: json['id'] ?? 0,
      serviceId: json['serviceId'] ?? 0,
      serviceName: json['serviceName'] ?? '',
      chargeType: json['chargeType'] ?? '',
      oldReading: (json['oldReading'] as num?)?.toDouble(),
      newReading: (json['newReading'] as num?)?.toDouble(),
      consumption: (json['consumption'] as num?)?.toDouble(),
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0,
    );
  }
}

class InvoiceResult {
  final int id;
  final String tenantId;
  final int contractId;
  final int roomId;
  final String? roomNumber;
  final String billingMonth;
  final double totalAmount;
  final double paidAmount;
  final double balanceDeduction;
  final String status; // PENDING | PARTIAL | PAID | VOID
  final String invoiceType;
  final String? dueDate;
  final List<InvoiceDetail> details;

  InvoiceResult({
    required this.id,
    required this.tenantId,
    required this.contractId,
    required this.roomId,
    this.roomNumber,
    required this.billingMonth,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceDeduction,
    required this.status,
    required this.invoiceType,
    this.dueDate,
    required this.details,
  });

  factory InvoiceResult.fromJson(Map<String, dynamic> json) {
    return InvoiceResult(
      id: json['id'] ?? 0,
      tenantId: json['tenantId'] ?? '',
      contractId: json['contractId'] ?? 0,
      roomId: json['roomId'] ?? 0,
      roomNumber: json['roomNumber'],
      billingMonth: json['billingMonth'] ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      balanceDeduction: (json['balanceDeduction'] as num?)?.toDouble() ?? 0,
      status: json['status'] ?? 'PENDING',
      invoiceType: json['invoiceType'] ?? '',
      dueDate: json['dueDate'],
      details: (json['details'] as List<dynamic>? ?? []).map((e) => InvoiceDetail.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class MeterReadingResult {
  final int id;
  final String? tenantId;
  final int roomId;
  final int serviceId;
  final String serviceName;
  final String billingMonth;
  final double oldReading;
  final double? newReading;
  final double? consumption;
  final String status; // PENDING | SUBMITTED | APPROVED | REJECTED

  MeterReadingResult({
    required this.id,
    this.tenantId,
    required this.roomId,
    required this.serviceId,
    required this.serviceName,
    required this.billingMonth,
    required this.oldReading,
    this.newReading,
    this.consumption,
    required this.status,
  });

  factory MeterReadingResult.fromJson(Map<String, dynamic> json) {
    return MeterReadingResult(
      id: json['id'] ?? 0,
      tenantId: json['tenantId'],
      roomId: json['roomId'] ?? 0,
      serviceId: json['serviceId'] ?? 0,
      serviceName: json['serviceName'] ?? '',
      billingMonth: json['billingMonth'] ?? '',
      oldReading: (json['oldReading'] as num?)?.toDouble() ?? 0,
      newReading: (json['newReading'] as num?)?.toDouble(),
      consumption: (json['consumption'] as num?)?.toDouble(),
      status: json['status'] ?? 'PENDING',
    );
  }
}

// ─── InvoiceService (mirror invoiceService.ts) ───────────────────────────────

class InvoiceService {
  /// UC73: Generate invoices — POST /api/v1/invoices/generate
  static Future<void> generate({required int motelId, required String billingMonth}) async {
    // billingMonth format: "YYYY-MM" → backend needs "YYYY-MM-01"
    final month = billingMonth.endsWith('-01') ? billingMonth : '$billingMonth-01';
    await ApiClient.post('/api/v1/invoices/generate', body: {
      'motelId': motelId,
      'billingMonth': month,
    });
  }

  /// UC74: List invoices — GET /api/v1/invoices
  static Future<PageResponse<InvoiceResult>> list({int? motelId, String? status, int page = 0, int size = 50}) async {
    final data = await ApiClient.get('/api/v1/invoices', params: {
      if (motelId != null) 'motelId': motelId,
      if (status != null) 'status': status,
      'page': page,
      'size': size,
    });
    return PageResponse.fromJson(data as Map<String, dynamic>, InvoiceResult.fromJson);
  }

  /// UC74 (Resident): List my invoices — GET /api/v1/invoices/me
  static Future<PageResponse<InvoiceResult>> listMine({String? status, int page = 0, int size = 20}) async {
    final data = await ApiClient.get('/api/v1/invoices/me', params: {
      if (status != null) 'status': status,
      'page': page,
      'size': size,
    });
    return PageResponse.fromJson(data as Map<String, dynamic>, InvoiceResult.fromJson);
  }

  /// UC75: Get invoice detail — GET /api/v1/invoices/{id}
  static Future<InvoiceResult> get(int invoiceId) async {
    final data = await ApiClient.get('/api/v1/invoices/$invoiceId');
    return InvoiceResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC77: Void invoice — DELETE /api/v1/invoices/{id}
  static Future<void> delete(int invoiceId) async {
    await ApiClient.delete('/api/v1/invoices/$invoiceId');
  }

  /// Get my credit balance — GET /api/v1/invoices/my-balance
  static Future<double> getMyBalance() async {
    final data = await ApiClient.get('/api/v1/invoices/my-balance');
    return (data as num).toDouble();
  }
}

// ─── MeterReadingService (mirror meterReadingService of invoiceService.ts) ──

class MeterReadingService {
  /// UC72: List meter readings — GET /api/v1/meter-readings
  static Future<PageResponse<MeterReadingResult>> list({int? roomId, String? status, int page = 0, int size = 100}) async {
    final data = await ApiClient.get('/api/v1/meter-readings', params: {
      if (roomId != null) 'roomId': roomId,
      if (status != null) 'status': status,
      'page': page,
      'size': size,
    });
    return PageResponse.fromJson(data as Map<String, dynamic>, MeterReadingResult.fromJson);
  }

  /// UC70: Submit meter reading — POST /api/v1/meter-readings
  static Future<MeterReadingResult> submit({
    required int roomId,
    required int serviceId,
    required String billingMonth,
    required double newReading,
    String? readingImageUrl,
  }) async {
    final data = await ApiClient.post('/api/v1/meter-readings', body: {
      'roomId': roomId,
      'serviceId': serviceId,
      'billingMonth': billingMonth,
      'newReading': newReading,
      if (readingImageUrl != null) 'readingImageUrl': readingImageUrl,
    });
    return MeterReadingResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC70: Approve reading — POST /api/v1/meter-readings/{id}/approve
  static Future<MeterReadingResult> approve(int readingId) async {
    final data = await ApiClient.post('/api/v1/meter-readings/$readingId/approve');
    return MeterReadingResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC70: Reject reading — POST /api/v1/meter-readings/{id}/reject
  static Future<MeterReadingResult> reject(int readingId, {String? reason}) async {
    final data = await ApiClient.post(
      '/api/v1/meter-readings/$readingId/reject',
      params: reason != null ? {'reason': reason} : null,
    );
    return MeterReadingResult.fromJson(data as Map<String, dynamic>);
  }
}

// ─── PaymentService (mirror paymentService of invoiceService.ts) ─────────────

class PaymentService {
  /// UC78: Manual payment — POST /api/v1/payments/manual
  static Future<void> pay({required int invoiceId, required double amount, required String paymentMethod}) async {
    await ApiClient.post('/api/v1/payments/manual', body: {
      'invoiceId': invoiceId,
      'amount': amount,
      'paymentMethod': paymentMethod,
    });
  }
}
