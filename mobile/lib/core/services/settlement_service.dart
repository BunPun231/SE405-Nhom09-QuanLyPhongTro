import '../network/api_client.dart';

double _d(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

double? _dn(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int? _in(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Một hạng mục hư hỏng/mất mát khi trả phòng (UC80 bước 3).
class DamageItem {
  final String itemName;
  final double penaltyFee;

  /// Ảnh bằng chứng dạng base64 (bắt buộc khi penaltyFee > 0 – BR01/BR80.3).
  final String? imageBase64;

  const DamageItem({required this.itemName, required this.penaltyFee, this.imageBase64});

  Map<String, dynamic> toJson() => {
        'itemName': itemName.trim(),
        'penaltyFee': penaltyFee,
        if (imageBase64 != null) 'imageUrl': imageBase64,
      };
}

/// Bảng kê tất toán (POST /api/v1/settlements/calculate).
class SettlementCalculation {
  final int contractId;
  final double deposit;
  final double currentDebt;
  final double proRatedRent;
  final double finalUtilities;
  final double repairFees;
  final double netAmount;

  SettlementCalculation({
    required this.contractId,
    required this.deposit,
    required this.currentDebt,
    required this.proRatedRent,
    required this.finalUtilities,
    required this.repairFees,
    required this.netAmount,
  });

  /// Tổng chi = Nợ cũ + Tiền phòng lẻ ngày + Điện nước cuối + Phạt hư hỏng.
  double get totalCharges => currentDebt + proRatedRent + finalUtilities + repairFees;

  SettlementOutcome get outcome => SettlementMath.outcomeOf(netAmount);

  factory SettlementCalculation.fromJson(Map<String, dynamic> json) {
    return SettlementCalculation(
      contractId: _in(json['contractId']) ?? 0,
      deposit: _d(json['deposit']),
      currentDebt: _d(json['currentDebt']),
      proRatedRent: _d(json['proRatedRent']),
      finalUtilities: _d(json['finalUtilities']),
      repairFees: _d(json['repairFees']),
      netAmount: _d(json['netAmount']),
    );
  }
}

/// Kết quả xác nhận tất toán (POST /api/v1/settlements/{id}/confirm).
class SettlementConfirmation {
  final int contractId;
  final String contractStatus;
  final String? roomStatus;
  final double depositSnapshot;
  final double oldDebtDeducted;
  final double settlementDeducted;
  final double netAmount;
  final int? settlementInvoiceId;
  final String? settlementInvoiceStatus;
  final double? settlementRemaining;
  final double? refundAmount;

  SettlementConfirmation({
    required this.contractId,
    required this.contractStatus,
    this.roomStatus,
    required this.depositSnapshot,
    required this.oldDebtDeducted,
    required this.settlementDeducted,
    required this.netAmount,
    this.settlementInvoiceId,
    this.settlementInvoiceStatus,
    this.settlementRemaining,
    this.refundAmount,
  });

  bool get liquidated => contractStatus == 'LIQUIDATED';

  factory SettlementConfirmation.fromJson(Map<String, dynamic> json) {
    final invoice = json['settlementInvoice'] is Map ? Map<String, dynamic>.from(json['settlementInvoice'] as Map) : null;
    final refund = json['refundTransaction'] is Map ? Map<String, dynamic>.from(json['refundTransaction'] as Map) : null;
    return SettlementConfirmation(
      contractId: _in(json['contractId']) ?? 0,
      contractStatus: (json['contractStatus'] ?? '').toString(),
      roomStatus: json['roomStatus']?.toString(),
      depositSnapshot: _d(json['depositSnapshot']),
      oldDebtDeducted: _d(json['oldDebtDeducted']),
      settlementDeducted: _d(json['settlementDeducted']),
      netAmount: _d(json['netAmount']),
      settlementInvoiceId: invoice == null ? null : _in(invoice['id']),
      settlementInvoiceStatus: invoice?['status']?.toString(),
      settlementRemaining: invoice == null ? null : _dn(invoice['remainingAmount']),
      refundAmount: refund == null ? null : _dn(refund['amount']),
    );
  }
}

/// Trạng thái tất toán của hợp đồng (GET /api/v1/settlements/{contractId}).
class SettlementStatus {
  final int contractId;
  final String contractStatus;
  final String? depositStatus;
  final String? roomStatus;
  final int? settlementInvoiceId;
  final String? settlementInvoiceStatus;
  final double? settlementTotal;
  final double? remainingAmount;
  final double? repairFees;

  SettlementStatus({
    required this.contractId,
    required this.contractStatus,
    this.depositStatus,
    this.roomStatus,
    this.settlementInvoiceId,
    this.settlementInvoiceStatus,
    this.settlementTotal,
    this.remainingAmount,
    this.repairFees,
  });

  bool get hasSettlement => settlementInvoiceId != null;

  /// Đã tạo bảng tất toán nhưng khách còn phải trả thêm (UC80 bước 5a).
  bool get awaitingExtraPayment =>
      hasSettlement && contractStatus == 'PENDING_LIQUIDATION' && settlementInvoiceStatus != 'PAID';

  /// Hóa đơn tất toán đã được thanh toán nhưng hợp đồng chưa đóng.
  bool get readyToClose =>
      hasSettlement && contractStatus == 'PENDING_LIQUIDATION' && settlementInvoiceStatus == 'PAID';

  factory SettlementStatus.fromJson(Map<String, dynamic> json) {
    return SettlementStatus(
      contractId: _in(json['contractId']) ?? 0,
      contractStatus: (json['contractStatus'] ?? '').toString(),
      depositStatus: json['depositStatus']?.toString(),
      roomStatus: json['roomStatus']?.toString(),
      settlementInvoiceId: _in(json['settlementInvoiceId']),
      settlementInvoiceStatus: json['settlementInvoiceStatus']?.toString(),
      settlementTotal: _dn(json['settlementTotal']),
      remainingAmount: _dn(json['remainingAmount']),
      repairFees: _dn(json['repairFees']),
    );
  }
}

enum SettlementOutcome { refund, collectMore, even }

/// Phép tính/kiểm tra thuần cho luồng tất toán (để test).
class SettlementMath {
  SettlementMath._();

  /// BR80.4: FinalBalance = Deposit − (CurrentDebt + ProRatedRent + FinalUtilities + RepairFees)
  static double finalBalance({
    required double deposit,
    required double currentDebt,
    required double proRatedRent,
    required double finalUtilities,
    required double repairFees,
  }) =>
      deposit - (currentDebt + proRatedRent + finalUtilities + repairFees);

  static SettlementOutcome outcomeOf(double net) {
    if (net > 0.5) return SettlementOutcome.refund;
    if (net < -0.5) return SettlementOutcome.collectMore;
    return SettlementOutcome.even;
  }

  static double repairTotal(List<DamageItem> items) => items.fold(0, (s, i) => s + i.penaltyFee);

  /// BR01 / BR80.3: mỗi hạng mục có phí > 0 phải có tên và ít nhất 1 ảnh bằng chứng.
  /// Trả về thông báo lỗi đầu tiên, hoặc null nếu hợp lệ.
  static String? validateDamages(List<DamageItem> items) {
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.penaltyFee < 0) return 'Hạng mục ${i + 1}: phí không được âm';
      if (item.penaltyFee > 0) {
        if (item.itemName.trim().isEmpty) return 'Hạng mục ${i + 1}: vui lòng nhập tên hư hỏng';
        if (item.imageBase64 == null || item.imageBase64!.isEmpty) {
          return 'Hạng mục "${item.itemName.trim()}" cần ít nhất 1 ảnh bằng chứng';
        }
      }
    }
    return null;
  }

  /// BR80.2: Chỉ số cuối phải ≥ chỉ số kỳ gần nhất (nếu biết).
  static String? validateReading(String label, double? value, {double? previous}) {
    if (value == null) return 'Vui lòng nhập chỉ số $label cuối';
    if (value < 0) return 'Chỉ số $label không được âm';
    if (previous != null && value < previous) {
      return 'Chỉ số $label cuối nhỏ hơn kỳ trước (${previous.toStringAsFixed(0)})';
    }
    return null;
  }
}

class SettlementService {
  SettlementService._();

  /// UC81: Ghi nhận ngày dự kiến trả phòng — POST /api/v1/settlements/schedule-moveout
  static Future<void> scheduleMoveOut(int contractId, {required DateTime moveOutDate, String? reason}) async {
    await ApiClient.post('/api/v1/settlements/schedule-moveout', body: {
      'contractId': contractId,
      'moveOutDate': _ymd(moveOutDate),
      if (reason != null && reason.isNotEmpty) 'moveOutReason': reason,
    });
  }

  static Map<String, dynamic> _body({
    required DateTime moveOutDate,
    required double finalElectricReading,
    required double finalWaterReading,
    required List<DamageItem> damages,
  }) =>
      {
        'moveOutDate': _ymd(moveOutDate),
        'finalElectricReading': finalElectricReading,
        'finalWaterReading': finalWaterReading,
        'damages': damages.where((d) => d.penaltyFee > 0).map((d) => d.toJson()).toList(),
      };

  /// UC80 bước 4: Bảng kê tất toán (không lưu dữ liệu).
  static Future<SettlementCalculation> calculate(
    int contractId, {
    required DateTime moveOutDate,
    required double finalElectricReading,
    required double finalWaterReading,
    List<DamageItem> damages = const [],
  }) async {
    // Bảng kê chỉ cần số tiền; ảnh được gửi khi xác nhận để tránh tải lên nhiều lần.
    final body = _body(
      moveOutDate: moveOutDate,
      finalElectricReading: finalElectricReading,
      finalWaterReading: finalWaterReading,
      damages: damages
          .map((d) => DamageItem(
                itemName: d.itemName,
                penaltyFee: d.penaltyFee,
                imageBase64: d.imageBase64 == null ? null : 'pending-upload',
              ))
          .toList(),
    );
    body['contractId'] = contractId;
    final data = await ApiClient.post('/api/v1/settlements/calculate', body: body);
    return SettlementCalculation.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// UC80 bước 5–7: Xác nhận tất toán (một giao dịch ở backend).
  static Future<SettlementConfirmation> confirm(
    int contractId, {
    required DateTime moveOutDate,
    required double finalElectricReading,
    required double finalWaterReading,
    List<DamageItem> damages = const [],
  }) async {
    final data = await ApiClient.post(
      '/api/v1/settlements/$contractId/confirm',
      body: _body(
        moveOutDate: moveOutDate,
        finalElectricReading: finalElectricReading,
        finalWaterReading: finalWaterReading,
        damages: damages,
      ),
    );
    return SettlementConfirmation.fromJson(Map<String, dynamic>.from(data as Map));
  }

  static Future<SettlementStatus> getStatus(int contractId) async {
    final data = await ApiClient.get('/api/v1/settlements/$contractId');
    return SettlementStatus.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// UC80 bước 5b/5c: Đóng hợp đồng sau khi khách trả thêm, hoặc đóng & ghi nhận nợ xấu.
  static Future<SettlementStatus> finalize(int contractId, {bool closeAsBadDebt = false, String? note}) async {
    final data = await ApiClient.post('/api/v1/settlements/$contractId/finalize', body: {
      'closeAsBadDebt': closeAsBadDebt,
      if (note != null) 'note': note,
    });
    return SettlementStatus.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
