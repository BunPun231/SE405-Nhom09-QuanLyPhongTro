import 'dart:convert';

import '../network/api_client.dart';
import 'motel_service.dart';

// PaymentService / TransactionResult (UC78, UC79) nằm ở payment_service.dart;
// export lại để các màn hình cũ chỉ import invoice_service.dart vẫn dùng được.
export 'payment_service.dart';

// ─── Định dạng & nhãn dùng chung (Module IX) ─────────────────────────────────

double _toDouble(dynamic v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

double? _toDoubleOrNull(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int _toInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

/// Định dạng tiền VND, làm tròn hàng đơn vị: 1500000 → "1.500.000đ" (BR74.5, BR75.8).
String formatVnd(num value, {bool withSymbol = true}) {
  final rounded = value.round();
  final negative = rounded < 0;
  final digits = rounded.abs().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
  return '${negative ? '-' : ''}$digits${withSymbol ? 'đ' : ''}';
}

/// Đọc số tiền người dùng nhập ("1.500.000", "1500000đ") → 1500000. Trả null nếu không hợp lệ.
double? parseVndInput(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[^0-9-]'), '');
  if (cleaned.isEmpty || cleaned == '-') return null;
  return double.tryParse(cleaned);
}

/// "2026-04-01" → "Tháng 4/2026".
String formatBillingMonth(String? raw) {
  if (raw == null || raw.isEmpty) return '-';
  final d = DateTime.tryParse(raw.length == 7 ? '$raw-01' : raw);
  if (d == null) return raw;
  return 'Tháng ${d.month}/${d.year}';
}

/// "2026-04-05" → "05/04/2026".
String formatDateVi(String? raw, {bool withTime = false}) {
  if (raw == null || raw.isEmpty) return '-';
  final d = DateTime.tryParse(raw);
  if (d == null) return raw;
  final local = d.isUtc || raw.contains('+') || raw.endsWith('Z') ? d.toLocal() : d;
  String two(int n) => n.toString().padLeft(2, '0');
  final date = '${two(local.day)}/${two(local.month)}/${local.year}';
  return withTime ? '${two(local.hour)}:${two(local.minute)} $date' : date;
}

/// Kỳ hóa đơn dạng "yyyy-MM" cho API.
String billingMonthKey(DateTime month) => '${month.year}-${month.month.toString().padLeft(2, '0')}';

/// Nhãn trạng thái hóa đơn (BR74.3).
String invoiceStatusLabel(String status) {
  switch (status) {
    case 'PENDING':
      return 'Chờ thanh toán';
    case 'PARTIAL':
      return 'Thanh toán một phần';
    case 'PAID':
      return 'Đã thanh toán';
    case 'VOID':
    case 'CANCELLED':
      return 'Đã hủy';
    default:
      return status;
  }
}

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

  /// Dòng phụ thu / giảm trừ / điều chỉnh sinh ra khi tái cấp hóa đơn (UC76).
  bool get isAdjustment =>
      chargeType == 'ADJUSTMENT' ||
      serviceName.startsWith('Phụ thu') ||
      serviceName.startsWith('Giảm trừ') ||
      serviceName.startsWith('Điều chỉnh');

  factory InvoiceDetail.fromJson(Map<String, dynamic> json) {
    final name = (json['serviceName'] ?? json['description'] ?? '').toString();
    final cost = _toDouble(json['totalCost'] ?? json['lineTotal']);
    final qty = _toDoubleOrNull(json['consumption'] ?? json['quantity']);
    final uPrice = _toDouble(json['unitPrice'] ?? json['basePrice']);
    final lower = name.toLowerCase();
    final isMeter = lower.contains('điện') || lower.contains('nước');
    final isAdj = lower.startsWith('phụ thu') || lower.startsWith('giảm trừ') || lower.startsWith('điều chỉnh');
    final charge = (json['chargeType'] ?? (isAdj ? 'ADJUSTMENT' : isMeter ? 'PER_INDEX' : 'FIXED')).toString();

    return InvoiceDetail(
      id: _toInt(json['id']),
      serviceId: _toInt(json['serviceId']),
      serviceName: name,
      chargeType: charge,
      oldReading: _toDoubleOrNull(json['oldReading']),
      newReading: _toDoubleOrNull(json['newReading']),
      consumption: qty,
      unitPrice: uPrice,
      totalCost: cost,
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
  final double? _remainingAmount;
  final String? createdAt;

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
    double? remainingAmount,
    this.createdAt,
  }) : _remainingAmount = remainingAmount;

  /// Số tiền còn phải đóng = Tổng − Đã trả − Khấu trừ số dư (BR74.7, BR75.5), không âm.
  double get remainingAmount {
    final r = _remainingAmount ?? (totalAmount - paidAmount - balanceDeduction);
    return r < 0 ? 0 : r;
  }

  bool get isUnpaid => status == 'PENDING' || status == 'PARTIAL';
  bool get isVoid => status == 'VOID' || status == 'CANCELLED';

  /// UC76 / UC77: chỉ hóa đơn PENDING chưa có thanh toán mới được hủy-tái cấp hoặc xóa.
  bool get canAdjust => status == 'PENDING' && paidAmount <= 0;
  bool get canDelete => canAdjust;

  String get roomLabel => roomNumber != null && roomNumber!.isNotEmpty ? 'Phòng $roomNumber' : 'Phòng #$roomId';

  Map<String, dynamic>? get snapshot {
    final raw = calculationSnapshot;
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  /// Hóa đơn bị hủy mà hóa đơn này tái cấp (UC76), nếu có.
  int? get replacesInvoiceId {
    final v = snapshot?['replacesInvoiceId'];
    return v == null ? null : _toInt(v);
  }

  factory InvoiceResult.fromJson(Map<String, dynamic> json) {
    return InvoiceResult(
      id: _toInt(json['id']),
      tenantId: json['tenantId']?.toString() ?? '',
      contractId: _toInt(json['contractId']),
      roomId: _toInt(json['roomId']),
      roomNumber: json['roomNumber']?.toString(),
      billingMonth: json['billingMonth']?.toString() ?? '',
      totalAmount: _toDouble(json['totalAmount']),
      paidAmount: _toDouble(json['paidAmount']),
      balanceDeduction: _toDouble(json['balanceDeduction']),
      status: json['status']?.toString() ?? 'PENDING',
      invoiceType: json['invoiceType']?.toString() ?? '',
      cancelReason: json['cancelReason']?.toString(),
      dueDate: json['dueDate']?.toString(),
      calculationSnapshot: json['calculationSnapshot'] is String
          ? json['calculationSnapshot']
          : (json['calculationSnapshot'] == null ? null : jsonEncode(json['calculationSnapshot'])),
      details: (json['details'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(InvoiceDetail.fromJson)
          .toList(),
      remainingAmount: _toDoubleOrNull(json['remainingAmount']),
      createdAt: json['createdAt']?.toString(),
    );
  }
}

/// Một dòng trong bảng kê hóa đơn (UC75), đã ghép chỉ số điện nước từ snapshot.
class InvoiceLine {
  final int detailId;
  final int serviceId;
  final String name;
  final String chargeType;
  final double? quantity;
  final double unitPrice;
  final double amount;
  final double? oldReading;
  final double? newReading;
  final bool isAdjustment;

  const InvoiceLine({
    required this.detailId,
    required this.serviceId,
    required this.name,
    required this.chargeType,
    this.quantity,
    required this.unitPrice,
    required this.amount,
    this.oldReading,
    this.newReading,
    this.isAdjustment = false,
  });

  bool get isMeter => oldReading != null && newReading != null;
  double? get consumption => isMeter ? (newReading! - oldReading!).clamp(0, double.infinity).toDouble() : null;

  /// Đơn vị hiển thị: nước dùng "khối", điện dùng "số".
  String get meterUnit => name.toLowerCase().contains('nước') ? 'khối' : 'số';
}

/// Ghép dòng chi tiết với snapshot để hiển thị chỉ số cũ / mới (BR75.3).
List<InvoiceLine> buildInvoiceLines(InvoiceResult inv) {
  final snapItems = (inv.snapshot?['items'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .toList();
  Map<String, dynamic>? snapFor(int serviceId) {
    if (serviceId == 0) return null;
    for (final item in snapItems) {
      if (_toInt(item['serviceId'], -1) == serviceId) return item;
    }
    return null;
  }

  if (inv.details.isNotEmpty) {
    return inv.details.map((d) {
      final snap = snapFor(d.serviceId);
      final chargeType = d.isAdjustment ? 'ADJUSTMENT' : (snap?['chargeType']?.toString() ?? d.chargeType);
      final meterType = chargeType == 'PER_INDEX' || chargeType == 'METERED';
      final oldR = d.oldReading ?? (meterType ? _toDoubleOrNull(snap?['oldReading']) : null);
      final newR = d.newReading ?? (meterType ? _toDoubleOrNull(snap?['newReading']) : null);
      return InvoiceLine(
        detailId: d.id,
        serviceId: d.serviceId,
        name: d.serviceName.isNotEmpty ? d.serviceName : (snap?['serviceName']?.toString() ?? 'Khoản phí'),
        chargeType: chargeType,
        quantity: d.consumption,
        unitPrice: d.unitPrice,
        amount: d.totalCost,
        oldReading: oldR,
        newReading: newR,
        isAdjustment: d.isAdjustment,
      );
    }).toList();
  }

  // Không có details: dựng tạm từ snapshot.
  return snapItems.map((item) {
    final chargeType = item['chargeType']?.toString() ?? 'FIXED';
    final meterType = chargeType == 'PER_INDEX' || chargeType == 'METERED';
    final base = _toDouble(item['basePrice']);
    final qty = _toDoubleOrNull(item['quantity']) ?? 1;
    return InvoiceLine(
      detailId: 0,
      serviceId: _toInt(item['serviceId']),
      name: item['serviceName']?.toString() ?? 'Khoản phí',
      chargeType: chargeType,
      quantity: qty,
      unitPrice: base,
      amount: chargeType == 'FIXED' || chargeType == 'ADJUSTMENT' ? base : base * qty,
      oldReading: meterType ? _toDoubleOrNull(item['oldReading']) : null,
      newReading: meterType ? _toDoubleOrNull(item['newReading']) : null,
      isAdjustment: chargeType == 'ADJUSTMENT',
    );
  }).toList();
}

/// Tổng hợp tiền của một danh sách hóa đơn (UC74: tổng, đã trả, còn lại). Bỏ qua hóa đơn đã hủy.
class InvoiceTotals {
  final double total;
  final double paid;
  final double remaining;
  final int count;

  const InvoiceTotals({required this.total, required this.paid, required this.remaining, required this.count});

  factory InvoiceTotals.of(Iterable<InvoiceResult> invoices) {
    double total = 0, paid = 0, remaining = 0;
    var count = 0;
    for (final inv in invoices) {
      if (inv.isVoid) continue;
      total += inv.totalAmount;
      paid += inv.paidAmount;
      remaining += inv.remainingAmount;
      count++;
    }
    return InvoiceTotals(total: total, paid: paid, remaining: remaining, count: count);
  }
}

/// Lọc phía client (tìm kiếm trong trang đã tải): theo mã HĐ, số phòng, kỳ, trạng thái, tháng, phòng.
List<InvoiceResult> filterInvoices(
  List<InvoiceResult> invoices, {
  String query = '',
  String? status,
  String? billingMonth,
  int? roomId,
}) {
  final q = query.trim().toLowerCase().replaceFirst('#', '');
  return invoices.where((inv) {
    if (status != null && status.isNotEmpty && inv.status != status) return false;
    if (billingMonth != null && billingMonth.isNotEmpty && !inv.billingMonth.startsWith(billingMonth)) return false;
    if (roomId != null && inv.roomId != roomId) return false;
    if (q.isEmpty) return true;
    final idOrRoom = '${inv.id}'.startsWith(q) || (inv.roomNumber ?? '').toLowerCase().contains(q);
    // Chuỗi toàn số (VD "202") chỉ so mã HĐ / số phòng, tránh khớp nhầm năm "2026".
    if (RegExp(r'^\d+$').hasMatch(q)) return idOrRoom;
    return idOrRoom ||
        inv.billingMonth.contains(q) ||
        formatBillingMonth(inv.billingMonth).toLowerCase().contains(q);
  }).toList();
}

/// Kết quả chạy tạo hóa đơn hàng loạt (UC73).
class SkippedInvoiceRoom {
  final int roomId;
  final String? roomNumber;
  final String reason;

  SkippedInvoiceRoom({required this.roomId, this.roomNumber, required this.reason});

  factory SkippedInvoiceRoom.fromJson(Map<String, dynamic> json) => SkippedInvoiceRoom(
        roomId: _toInt(json['roomId']),
        roomNumber: json['roomNumber']?.toString(),
        reason: json['reason']?.toString() ?? '',
      );

  String get roomLabel => roomNumber != null && roomNumber!.isNotEmpty ? 'Phòng $roomNumber' : 'Phòng #$roomId';
  bool get alreadyInvoiced => reason.startsWith('Đã có hóa đơn');
  bool get missingReading => reason.contains('APPROVED') || reason.toLowerCase().contains('chỉ số');
  bool get isError => !alreadyInvoiced && !missingReading;
}

class InvoiceGenerationResult {
  final List<InvoiceResult> invoices;
  final List<SkippedInvoiceRoom> skippedRooms;

  InvoiceGenerationResult({required this.invoices, required this.skippedRooms});

  factory InvoiceGenerationResult.fromJson(Map<String, dynamic>? json) => InvoiceGenerationResult(
        invoices: (json?['invoices'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(InvoiceResult.fromJson)
            .toList(),
        skippedRooms: (json?['skippedRooms'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(SkippedInvoiceRoom.fromJson)
            .toList(),
      );

  int get createdCount => invoices.length;
  List<SkippedInvoiceRoom> get missingReadingRooms => skippedRooms.where((r) => r.missingReading).toList();
  List<SkippedInvoiceRoom> get alreadyInvoicedRooms => skippedRooms.where((r) => r.alreadyInvoiced).toList();
  List<SkippedInvoiceRoom> get errorRooms => skippedRooms.where((r) => r.isError).toList();
  double get createdTotal => invoices.fold(0, (s, i) => s + i.totalAmount);
}

/// Khoản phụ thu (amount > 0) hoặc giảm trừ (amount < 0) khi tái cấp hóa đơn (UC76).
class InvoiceAdjustmentItem {
  final String description;
  final double amount;

  const InvoiceAdjustmentItem({required this.description, required this.amount});

  bool get isSurcharge => amount > 0;
  Map<String, dynamic> toJson() => {'description': description.trim(), 'amount': amount.round()};
}

/// Tính lại tổng hóa đơn khi điều chỉnh (UC76 - "Recalculate total automatically").
///
/// [editedAmounts]: detailId → số tiền đúng của dòng.
/// [correctedReadings]: serviceId → chỉ số mới đúng (ước tính theo đơn giá dòng, bậc thang sẽ do máy chủ tính lại).
class InvoiceAdjustmentCalculator {
  final List<InvoiceLine> lines;
  final Map<int, double> editedAmounts;
  final Map<int, double> correctedReadings;
  final List<InvoiceAdjustmentItem> adjustments;

  const InvoiceAdjustmentCalculator({
    required this.lines,
    this.editedAmounts = const {},
    this.correctedReadings = const {},
    this.adjustments = const [],
  });

  double get originalTotal => lines.fold(0, (s, l) => s + l.amount);

  /// Tổng mới ước tính.
  double get newTotal {
    double total = 0;
    final meterLinesByService = <int, List<InvoiceLine>>{};
    for (final l in lines) {
      if (l.isMeter && correctedReadings.containsKey(l.serviceId)) {
        meterLinesByService.putIfAbsent(l.serviceId, () => []).add(l);
        continue;
      }
      total += editedAmounts[l.detailId] ?? l.amount;
    }
    meterLinesByService.forEach((serviceId, group) {
      final first = group.first;
      final newReading = correctedReadings[serviceId]!;
      final newConsumption = (newReading - first.oldReading!).clamp(0, double.infinity).toDouble();
      if (group.length == 1 && first.unitPrice > 0) {
        total += newConsumption * first.unitPrice;
      } else {
        // Nhiều bậc giá: giữ tỷ lệ giá trung bình hiện tại.
        final oldConsumption = first.consumption ?? 0;
        final oldAmount = group.fold<double>(0, (s, l) => s + l.amount);
        total += oldConsumption > 0 ? oldAmount / oldConsumption * newConsumption : oldAmount;
      }
    });
    for (final a in adjustments) {
      total += a.amount;
    }
    return total.roundToDouble();
  }

  double get difference => newTotal - originalTotal;

  /// Có dòng bậc thang nên số liệu chỉ là ước tính.
  bool get isApproximate {
    final counts = <int, int>{};
    for (final l in lines) {
      if (l.isMeter && correctedReadings.containsKey(l.serviceId)) {
        counts[l.serviceId] = (counts[l.serviceId] ?? 0) + 1;
      }
    }
    return counts.values.any((c) => c > 1);
  }

  bool get hasChanges =>
      adjustments.any((a) => a.amount != 0) ||
      correctedReadings.isNotEmpty ||
      editedAmounts.entries.any((e) => lines.any((l) => l.detailId == e.key && l.amount != e.value));

  /// Kiểm tra trước khi gửi; trả về thông báo lỗi hoặc null nếu hợp lệ.
  String? validate(String reason) {
    if (reason.trim().isEmpty) return 'Vui lòng nhập lý do hủy và tái cấp.';
    for (final a in adjustments) {
      if (a.amount != 0 && a.description.trim().isEmpty) return 'Mỗi khoản phụ thu/giảm trừ cần có mô tả.';
    }
    for (final l in lines) {
      final v = correctedReadings[l.serviceId];
      if (l.isMeter && v != null && v < l.oldReading!) {
        return 'Chỉ số mới của ${l.name} không được nhỏ hơn chỉ số cũ (${l.oldReading!.toStringAsFixed(0)}).';
      }
    }
    if (newTotal < 0) return 'Tổng tiền sau điều chỉnh không được âm.';
    return null;
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
  /// Số bản ghi mỗi trang (BR74.8: 15–20).
  static const int pageSize = 20;

  /// UC73: Tạo hóa đơn tháng cho một khu trọ — POST /api/v1/invoices/generate.
  /// Trả về số hóa đơn đã tạo và các phòng bị bỏ qua. Chạy lại không tạo trùng.
  static Future<InvoiceGenerationResult> generate({required int motelId, required String billingMonth}) async {
    // billingMonth format: "YYYY-MM" → backend needs "YYYY-MM-01"
    final month = billingMonth.length == 7 ? '$billingMonth-01' : billingMonth;
    final data = await ApiClient.post('/api/v1/invoices/generate', body: {
      'motelId': motelId,
      'billingMonth': month,
    });
    return InvoiceGenerationResult.fromJson(data is Map<String, dynamic> ? data : null);
  }

  /// UC74: List invoices — GET /api/v1/invoices (Quản lý).
  static Future<PageResponse<InvoiceResult>> list({
    int? motelId,
    String? status,
    String? billingMonth,
    int? roomId,
    int page = 0,
    int size = 50,
  }) async {
    final data = await ApiClient.get('/api/v1/invoices', params: {
      if (motelId != null) 'motelId': motelId,
      if (status != null && status.isNotEmpty) 'status': status,
      if (billingMonth != null && billingMonth.isNotEmpty) 'billingMonth': billingMonth,
      if (roomId != null) 'roomId': roomId,
      'page': page,
      'size': size,
    });
    return PageResponse.fromJson(data as Map<String, dynamic>, InvoiceResult.fromJson);
  }

  /// UC74 (Resident): List my invoices — GET /api/v1/invoices/me
  static Future<PageResponse<InvoiceResult>> listMine({
    String? status,
    String? billingMonth,
    int page = 0,
    int size = 20,
  }) async {
    final data = await ApiClient.get('/api/v1/invoices/me', params: {
      if (status != null && status.isNotEmpty) 'status': status,
      if (billingMonth != null && billingMonth.isNotEmpty) 'billingMonth': billingMonth,
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

  /// UC76: Hủy hóa đơn PENDING và tái cấp hóa đơn mới — POST /api/v1/invoices/{id}/adjust.
  /// Trả về hóa đơn MỚI.
  static Future<InvoiceResult> adjust(
    int invoiceId, {
    required String reason,
    Map<int, double> correctedReadings = const {},
    Map<int, double> editedAmounts = const {},
    List<InvoiceAdjustmentItem> adjustments = const [],
  }) async {
    final data = await ApiClient.post('/api/v1/invoices/$invoiceId/adjust', body: {
      'reason': reason.trim(),
      'correctedReadings': correctedReadings.map((k, v) => MapEntry('$k', v)),
      'customAdjustments': editedAmounts.map((k, v) => MapEntry('$k', v.round())),
      'adjustments': adjustments.where((a) => a.amount != 0).map((a) => a.toJson()).toList(),
    });
    return InvoiceResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC77: Xóa (mềm) hóa đơn PENDING chưa có thanh toán — DELETE /api/v1/invoices/{id}?reason=
  static Future<void> delete(int invoiceId, {String? reason}) async {
    final query = reason != null && reason.trim().isNotEmpty
        ? '?reason=${Uri.encodeQueryComponent(reason.trim())}'
        : '';
    await ApiClient.delete('/api/v1/invoices/$invoiceId$query');
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
    await ApiClient.post('/api/v1/meter-readings/bulk-approve', body: ids);
  }
}
