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
    final name = (json['serviceName'] ?? json['description'] ?? '').toString();
    final cost = (json['totalCost'] ?? json['lineTotal'] ?? 0) as num;
    final qty = (json['consumption'] ?? json['quantity']) as num?;
    final uPrice = (json['unitPrice'] ?? json['basePrice'] ?? 0) as num;
    final isMeter = name.toLowerCase().contains('điện') || name.toLowerCase().contains('nước');
    final charge = (json['chargeType'] ?? (isMeter ? 'PER_INDEX' : 'FIXED')).toString();

    return InvoiceDetail(
      id: json['id'] ?? 0,
      serviceId: json['serviceId'] ?? 0,
      serviceName: name,
      chargeType: charge,
      oldReading: (json['oldReading'] as num?)?.toDouble(),
      newReading: (json['newReading'] as num?)?.toDouble(),
      consumption: qty?.toDouble(),
      unitPrice: uPrice.toDouble(),
      totalCost: cost.toDouble(),
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
  final String? cancelReason;
  final String? dueDate;
  final String? calculationSnapshot;
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
    this.cancelReason,
    this.dueDate,
    this.calculationSnapshot,
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
      cancelReason: json['cancelReason'],
      dueDate: json['dueDate'],
      calculationSnapshot: json['calculationSnapshot'] is String
          ? json['calculationSnapshot']
          : json['calculationSnapshot']?.toString(),
      details: (json['details'] as List<dynamic>? ?? []).map((e) => InvoiceDetail.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class InvoicePaymentInfoResult {
  final String bankId;
  final String bankAccount;
  final String accountHolder;
  final String bankName;
  final double amount;
  final String memo;
  final String qrUrl;

  InvoicePaymentInfoResult({
    required this.bankId,
    required this.bankAccount,
    required this.accountHolder,
    required this.bankName,
    required this.amount,
    required this.memo,
    required this.qrUrl,
  });

  factory InvoicePaymentInfoResult.fromJson(Map<String, dynamic> json) {
    return InvoicePaymentInfoResult(
      bankId: json['bankId']?.toString() ?? '',
      bankAccount: json['bankAccount']?.toString() ?? '',
      accountHolder: json['accountHolder']?.toString() ?? '',
      bankName: json['bankName']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      memo: json['memo']?.toString() ?? '',
      qrUrl: json['qrUrl']?.toString() ?? '',
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
  final String? imageUrl;

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
    this.imageUrl,
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
      imageUrl: json['imageUrl'] ?? json['readingImageUrl'],
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

  /// UC78: Get VietQR payment info — GET /api/v1/invoices/{id}/payment-info
  static Future<InvoicePaymentInfoResult> getPaymentInfo(int invoiceId) async {
    final data = await ApiClient.get('/api/v1/invoices/$invoiceId/payment-info');
    return InvoicePaymentInfoResult.fromJson(data as Map<String, dynamic>);
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

  /// Get any resident's credit balance — GET /api/v1/invoices/balance/{residentId}
  static Future<double> getResidentBalance(String residentId) async {
    final data = await ApiClient.get('/api/v1/invoices/balance/$residentId');
    return (data as num).toDouble();
  }

  /// Get multiple residents' credit balances — GET /api/v1/invoices/balances
  static Future<Map<String, double>> getResidentBalances(List<String> residentIds) async {
    if (residentIds.isEmpty) return {};
    final data = await ApiClient.get('/api/v1/invoices/balances', params: {
      'residentIds': residentIds.join(','),
    });
    final map = data as Map<String, dynamic>;
    return map.map((key, value) => MapEntry(key, (value as num).toDouble()));
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

  /// Bulk approve — POST /api/v1/meter-readings/bulk-approve
  static Future<void> bulkApprove(List<int> ids) async {
    await ApiClient.post('/api/v1/meter-readings/bulk-approve', body: {'ids': ids});
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
