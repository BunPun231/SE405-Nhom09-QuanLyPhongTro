import 'dart:convert';

import '../network/api_client.dart';
import 'motel_service.dart';

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

double? _toDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int _toInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

String? _str(dynamic v) => v?.toString();

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
  final String depositStatus; // UNPAID | PAID | REFUNDED | DEDUCTED
  final String status; // ACTIVE | DRAFT | PENDING_LIQUIDATION | LIQUIDATED | CANCELED
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

  /// Mã hiển thị: ưu tiên mã hợp đồng từ backend, nếu không có dùng HĐ-{id}.
  String get displayCode => contractCode ?? 'HĐ-$id';

  factory ContractResult.fromJson(Map<String, dynamic> json) {
    return ContractResult(
      id: _toInt(json['id']),
      contractCode: _str(json['contractCode']),
      tenantId: _str(json['tenantId']) ?? '',
      roomId: _toInt(json['roomId']),
      primaryResidentUserId: _str(json['primaryResidentUserId']) ?? '',
      startDate: _str(json['startDate']) ?? '',
      endDate: _str(json['endDate']) ?? '',
      rentPrice: _toDouble(json['rentPrice']),
      depositAmount: _toDouble(json['depositAmount']),
      depositStatus: _str(json['depositStatus']) ?? 'UNPAID',
      status: _str(json['status']) ?? 'DRAFT',
      billingDate: _str(json['billingDate']),
      billingCycleDay: json['billingCycleDay'] == null ? null : _toInt(json['billingCycleDay']),
      paymentCycleMonths: json['paymentCycleMonths'] == null ? null : _toInt(json['paymentCycleMonths']),
      intendedMoveOutDate: _str(json['intendedMoveOutDate']),
      pdfUrl: _str(json['pdfUrl']),
      createdAt: _str(json['createdAt']),
      updatedAt: _str(json['updatedAt']),
      notes: _str(json['notes']),
      residentUserIds: (json['residentUserIds'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );
  }
}

/// Bản ghi phụ lục hợp đồng (backend: ContractAppendixResult).
/// Ngoài các loại phụ lục UC66 (RENEW, PRICE_CHANGE, MANUAL_CLAUSE), backend còn lưu
/// DEPOSIT_COLLECTED (lịch sử thu cọc UC69) và ATTACHMENT (tệp đính kèm US63.3).
class ContractAppendixResult {
  final int id;
  final int contractId;
  final String type;
  final String? effectiveDate;
  final double? newRentPrice;
  final String? metadata;
  final String? createdBy;
  final String createdAt;

  ContractAppendixResult({
    required this.id,
    required this.contractId,
    required this.type,
    this.effectiveDate,
    this.newRentPrice,
    this.metadata,
    this.createdBy,
    required this.createdAt,
  });

  factory ContractAppendixResult.fromJson(Map<String, dynamic> json) {
    return ContractAppendixResult(
      id: _toInt(json['id']),
      contractId: _toInt(json['contractId']),
      type: _str(json['appendixType'] ?? json['type']) ?? '',
      effectiveDate: _str(json['effectiveDate']),
      newRentPrice: _toDoubleOrNull(json['newRentPrice']),
      metadata: _str(json['metadata']),
      createdBy: _str(json['createdBy']),
      createdAt: _str(json['createdAt']) ?? '',
    );
  }

  /// Metadata dạng JSON (nếu parse được), ngược lại trả về map rỗng.
  Map<String, dynamic> get meta {
    final raw = metadata;
    if (raw == null || raw.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is String) {
        final again = jsonDecode(decoded);
        if (again is Map<String, dynamic>) return again;
      }
    } catch (_) {}
    return {'note': raw};
  }

  String? get reason => meta['reason']?.toString();
  String? get newEndDate => meta['newEndDate']?.toString();
  String? get clause => (meta['clause'] ?? meta['note'])?.toString();

  bool get isDepositRecord => type == 'DEPOSIT_COLLECTED';
  bool get isAttachment => type == 'ATTACHMENT';
  bool get isAmendment => !isDepositRecord && !isAttachment;
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
  final List<Map<String, dynamic>> serviceItems;
  final int appendicesCount;
  final String? roomNumber;
  final String? motelName;
  final String? primaryResidentFullName;
  final String? primaryResidentPhone;
  final String? cancelReason;
  final String? moveOutReason;

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
    this.serviceItems = const [],
    this.appendicesCount = 0,
    this.roomNumber,
    this.motelName,
    this.primaryResidentFullName,
    this.primaryResidentPhone,
    this.cancelReason,
    this.moveOutReason,
  });

  String get displayCode => 'HĐ-$id';

  factory ContractDetailResult.fromJson(Map<String, dynamic> json) {
    return ContractDetailResult(
      id: _toInt(json['id']),
      tenantId: _str(json['tenantId']) ?? '',
      roomId: _toInt(json['roomId']),
      motelId: json['motelId'] == null ? null : _toInt(json['motelId']),
      primaryResidentUserId: _str(json['primaryResidentUserId']) ?? '',
      rentPrice: _toDouble(json['rentPrice']),
      startDate: _str(json['startDate']) ?? '',
      endDate: _str(json['endDate']) ?? '',
      depositAmount: _toDouble(json['depositAmount']),
      depositStatus: _str(json['depositStatus']) ?? 'UNPAID',
      status: _str(json['status']) ?? 'DRAFT',
      billingDate: _str(json['billingDate']),
      billingCycleDay: json['billingCycleDay'] == null ? null : _toInt(json['billingCycleDay']),
      paymentCycleMonths: json['paymentCycleMonths'] == null ? null : _toInt(json['paymentCycleMonths']),
      intendedMoveOutDate: _str(json['intendedMoveOutDate']),
      pdfUrl: _str(json['pdfUrl']),
      createdAt: _str(json['createdAt']),
      residentUserIds: (json['residentUserIds'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      serviceItems: (json['serviceItems'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      appendicesCount: _toInt(json['appendicesCount']),
      roomNumber: _str(json['roomNumber']),
      motelName: _str(json['motelName']),
      primaryResidentFullName: _str(json['primaryResidentFullName']),
      primaryResidentPhone: _str(json['primaryResidentPhone']),
      cancelReason: _str(json['cancelReason']),
      moveOutReason: _str(json['moveOutReason']),
    );
  }
}

/// Hóa đơn liên quan hợp đồng (GET /api/contracts/{id}/invoices).
class ContractInvoiceSummary {
  final int id;
  final String? billingMonth;
  final String invoiceType; // MONTHLY | SETTLEMENT
  final String status; // PENDING | PARTIAL | PAID | VOID
  final double totalAmount;
  final double paidAmount;
  final double balanceDeduction;
  final double remainingAmount;
  final String? dueDate;

  ContractInvoiceSummary({
    required this.id,
    this.billingMonth,
    required this.invoiceType,
    required this.status,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceDeduction,
    required this.remainingAmount,
    this.dueDate,
  });

  bool get isOutstanding => (status == 'PENDING' || status == 'PARTIAL') && remainingAmount > 0;
  bool get hasPayment => status == 'PAID' || paidAmount > 0;

  factory ContractInvoiceSummary.fromJson(Map<String, dynamic> json) {
    return ContractInvoiceSummary(
      id: _toInt(json['id']),
      billingMonth: _str(json['billingMonth']),
      invoiceType: _str(json['invoiceType']) ?? 'MONTHLY',
      status: _str(json['status']) ?? 'PENDING',
      totalAmount: _toDouble(json['totalAmount']),
      paidAmount: _toDouble(json['paidAmount']),
      balanceDeduction: _toDouble(json['balanceDeduction']),
      remainingAmount: _toDouble(json['remainingAmount']),
      dueDate: _str(json['dueDate']),
    );
  }
}

/// Kết quả kiểm tra điều khoản hợp đồng (UC63, BR63.3).
class ContractTermsCheck {
  final String? error;
  const ContractTermsCheck(this.error);
  bool get ok => error == null;
}

/// Quy tắc nghiệp vụ thuần (không gọi API) dùng cho màn hình hợp đồng; tách riêng để test.
class ContractRules {
  ContractRules._();

  /// BR63.3: Ngày kết thúc > ngày bắt đầu; giá thuê và tiền cọc > 0.
  static ContractTermsCheck validateTerms({
    required DateTime? start,
    required DateTime? end,
    required double? rent,
    required double? deposit,
  }) {
    if (start == null) return const ContractTermsCheck('Vui lòng chọn ngày bắt đầu');
    if (end == null) return const ContractTermsCheck('Vui lòng chọn ngày kết thúc');
    if (!_dateOnly(end).isAfter(_dateOnly(start))) {
      return const ContractTermsCheck('Ngày kết thúc phải sau ngày bắt đầu');
    }
    if (rent == null || rent <= 0) return const ContractTermsCheck('Giá thuê phải lớn hơn 0');
    if (deposit == null || deposit <= 0) return const ContractTermsCheck('Tiền cọc phải lớn hơn 0');
    return const ContractTermsCheck(null);
  }

  static DateTime _dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  /// Cộng số tháng, kẹp ngày về cuối tháng nếu tháng đích ngắn hơn (31/01 + 1 tháng = 28/02).
  static DateTime addMonths(DateTime date, int months) {
    final totalMonths = date.year * 12 + (date.month - 1) + months;
    final year = totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, date.day > lastDay ? lastDay : date.day);
  }

  /// Thời hạn hợp đồng tính theo tháng tròn (dùng để hiển thị "12 tháng").
  static int durationMonths(DateTime start, DateTime end) {
    var months = (end.year - start.year) * 12 + (end.month - start.month);
    if (end.day < start.day) months -= 1;
    return months < 0 ? 0 : months;
  }

  /// BR63.5 / BR90: Nếu ngày bắt đầu không trùng ngày chốt sổ, tiền phòng kỳ đầu
  /// = (Giá thuê / 30) × số ngày ở thực tế đến ngày chốt, làm tròn đến hàng nghìn.
  /// Trả về null khi không cần tính lẻ ngày.
  static ProRatedRent? proRatedFirstRent({
    required DateTime start,
    required double rent,
    int billingCycleDay = 31,
  }) {
    final s = DateTime.utc(start.year, start.month, start.day);
    final cycleEnd = firstBillingDate(s, billingCycleDay);
    final previousCycleEnd = _cycleDayIn(cycleEnd.year, cycleEnd.month - 1, billingCycleDay);
    // Bắt đầu đúng ngày đầu kỳ (ngay sau ngày chốt kỳ trước) → kỳ đầu trọn tháng, không lẻ ngày.
    if (s == previousCycleEnd.add(const Duration(days: 1))) return null;
    final days = cycleEnd.difference(s).inDays + 1;
    final raw = rent / 30 * days;
    final rounded = (raw / 1000).round() * 1000.0;
    return ProRatedRent(days: days, amount: rounded, until: cycleEnd);
  }

  static DateTime _cycleDayIn(int year, int month, int cycleDay) {
    final first = DateTime.utc(year, month, 1);
    final last = DateTime.utc(first.year, first.month + 1, 0).day;
    return DateTime.utc(first.year, first.month, cycleDay >= 31 || cycleDay > last ? last : cycleDay);
  }

  /// Ngày chốt kỳ đầu tiên (giống logic backend khi tạo hợp đồng). Trả về ngày UTC.
  static DateTime firstBillingDate(DateTime start, int billingCycleDay) {
    final s = DateTime.utc(start.year, start.month, start.day);
    final thisMonth = _cycleDayIn(s.year, s.month, billingCycleDay);
    if (!s.isAfter(thisMonth)) return thisMonth;
    return _cycleDayIn(s.year, s.month + 1, billingCycleDay);
  }

  /// BR64.4: Sắp hết hạn khi 0 ≤ (EndDate − hôm nay) ≤ 30 ngày và hợp đồng đang hiệu lực.
  static bool isExpiringSoon(String status, String endDate, {DateTime? today}) {
    if (status != 'ACTIVE') return false;
    final end = DateTime.tryParse(endDate);
    if (end == null) return false;
    final now = _dateOnly(today ?? DateTime.now());
    final diff = _dateOnly(end).difference(now).inDays;
    return diff >= 0 && diff <= 30;
  }

  static bool isExpired(String status, String endDate, {DateTime? today}) {
    if (status != 'ACTIVE') return false;
    final end = DateTime.tryParse(endDate);
    if (end == null) return false;
    return _dateOnly(end).isBefore(_dateOnly(today ?? DateTime.now()));
  }

  /// BR64.3: Ánh xạ trạng thái máy → nhãn hiển thị.
  static String statusLabel(String status) {
    switch (status) {
      case 'ACTIVE':
        return 'Đang hiệu lực';
      case 'DRAFT':
        return 'Chờ thu cọc';
      case 'PENDING_LIQUIDATION':
        return 'Chờ tất toán';
      case 'LIQUIDATED':
        return 'Đã thanh lý';
      case 'CANCELED':
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  /// BR65.3: Trạng thái tiền cọc.
  static String depositLabel(String status) {
    switch (status) {
      case 'UNPAID':
        return 'Chờ thu';
      case 'PAID':
        return 'Đã thu';
      case 'REFUNDED':
        return 'Đã hoàn';
      case 'DEDUCTED':
        return 'Đã khấu trừ';
      default:
        return status;
    }
  }

  static String appendixLabel(String type) {
    switch (type) {
      case 'RENEW':
        return 'Gia hạn';
      case 'PRICE_CHANGE':
        return 'Điều chỉnh giá thuê';
      case 'MANUAL_CLAUSE':
        return 'Bổ sung điều khoản';
      case 'MOVE_OUT_NOTICE':
        return 'Báo trả phòng';
      case 'DEPOSIT_COLLECTED':
        return 'Thu tiền cọc';
      case 'ATTACHMENT':
        return 'Tệp đính kèm';
      default:
        return type;
    }
  }

  static String paymentMethodLabel(String? method) {
    switch (method) {
      case 'BANK_TRANSFER':
        return 'Chuyển khoản';
      case 'CASH':
        return 'Tiền mặt';
      default:
        return method ?? '—';
    }
  }

  /// US67.1: Chỉ hủy được khi chưa có hóa đơn đã thanh toán và không còn nợ.
  /// Trả về lý do chặn, hoặc null nếu được phép hủy.
  static String? cancelBlockReason(String status, List<ContractInvoiceSummary> invoices) {
    if (status == 'CANCELED' || status == 'CANCELLED') return 'Hợp đồng đã bị hủy.';
    if (status == 'LIQUIDATED') return 'Hợp đồng đã thanh lý.';
    if (status == 'PENDING_LIQUIDATION') return 'Hợp đồng đang chờ tất toán, hãy dùng chức năng Tất toán.';
    final valid = invoices.where((i) => i.status != 'VOID');
    if (valid.any((i) => i.hasPayment)) {
      return 'Hợp đồng đã có hóa đơn được thanh toán. Hãy dùng chức năng Tất toán thay vì Hủy.';
    }
    final debt = valid.where((i) => i.isOutstanding).fold<double>(0, (s, i) => s + i.remainingAmount);
    if (debt > 0) return 'Hợp đồng còn công nợ chưa thanh toán. Cần thu hết nợ trước khi hủy.';
    return null;
  }
}

class ProRatedRent {
  final int days;
  final double amount;
  final DateTime until;
  const ProRatedRent({required this.days, required this.amount, required this.until});
}

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

typedef ContractApiService = ContractService;

class ContractService {
  /// List all contracts for current tenant — GET /api/contracts
  static Future<List<ContractResult>> listAll() async {
    final data = await ApiClient.get('/api/contracts');
    if (data is List) {
      return data.map((e) => ContractResult.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// UC64: Danh sách hợp đồng theo khu trọ, phân trang — GET /api/contracts/motels/{motelId}
  /// [status]: ACTIVE | DRAFT | PENDING_LIQUIDATION | LIQUIDATED | CANCELED; [expiring]: sắp hết hạn
  /// (≤ 30 ngày); [roomId]: lọc theo phòng.
  static Future<PageResponse<ContractResult>> listByMotel(
    int motelId, {
    String? status,
    bool expiring = false,
    int? roomId,
    int page = 0,
    int size = 20,
  }) async {
    final data = await ApiClient.get('/api/contracts/motels/$motelId', params: {
      if (status != null && status != 'ALL') 'status': status,
      if (expiring) 'expiring': true,
      if (roomId != null) 'roomId': roomId,
      'page': page,
      'size': size,
      'sort': 'createdAt,desc',
    });
    return PageResponse.fromJson(data as Map<String, dynamic>, ContractResult.fromJson);
  }

  /// Danh sách hợp đồng (không phân trang phía server), giữ để tương thích.
  static Future<PageResponse<ContractResult>> list({int? roomId, String? status, int page = 0, int size = 50}) async {
    final all = await listAll();
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

  /// List active contracts — GET /api/contracts/active (MANAGER/ADMIN)
  static Future<List<ContractResult>> listActive() async {
    final data = await ApiClient.get('/api/contracts/active');
    return (data as List<dynamic>).map((e) => ContractResult.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Hợp đồng của khách thuê đang đăng nhập — GET /api/contracts/resident/{userId}
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

  /// GET /api/contracts/{id}
  static Future<ContractResult> get(int id) async {
    final data = await ApiClient.get('/api/contracts/$id');
    return ContractResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC65: GET /api/contracts/{id}/detail
  static Future<ContractDetailResult> getDetail(int id) async {
    final data = await ApiClient.get('/api/contracts/$id/detail');
    return ContractDetailResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC63: POST /api/contracts
  static Future<ContractResult> create(Map<String, dynamic> body) async {
    final data = await ApiClient.post('/api/contracts', body: body);
    return ContractResult.fromJson(data as Map<String, dynamic>);
  }

  /// Dựng body tạo hợp đồng khớp ContractCreateRequestBody của backend.
  static Map<String, dynamic> buildCreateBody({
    required int roomId,
    String? residentUserId,
    String? newResidentFullName,
    String? newResidentPhone,
    String? newResidentIdCard,
    String? newResidentEmail,
    required DateTime startDate,
    required DateTime endDate,
    required double rentPrice,
    required double depositAmount,
    int billingCycleDay = 31,
    int paymentCycleMonths = 1,
    List<String> extraResidentIds = const [],
  }) {
    return {
      'roomId': roomId,
      if (residentUserId != null && residentUserId.isNotEmpty) 'primaryResidentUserId': residentUserId,
      if (residentUserId == null || residentUserId.isEmpty) ...{
        'primaryResidentFullName': newResidentFullName,
        'primaryResidentPhone': newResidentPhone,
        'primaryResidentIdCardNumber': newResidentIdCard,
        if (newResidentEmail != null && newResidentEmail.isNotEmpty) 'primaryResidentEmail': newResidentEmail,
      },
      'startDate': _ymd(startDate),
      'endDate': _ymd(endDate),
      'rentPrice': rentPrice,
      'depositAmount': depositAmount,
      'depositStatus': 'UNPAID',
      'billingCycleDay': billingCycleDay,
      'paymentCycleMonths': paymentCycleMonths,
      if (extraResidentIds.isNotEmpty) 'residentUserIds': extraResidentIds,
    };
  }

  /// UC66: Gia hạn / điều chỉnh giá / bổ sung điều khoản — POST /api/contracts/{id}/adjustments.
  /// [reason] bắt buộc ở phía app (ghi vết audit).
  static Future<ContractAppendixResult> adjust(
    int contractId, {
    required String type,
    required String reason,
    DateTime? effectiveDate,
    DateTime? newEndDate,
    double? newRentPrice,
    DateTime? intendedMoveOutDate,
    String? clause,
  }) async {
    final data = await ApiClient.post('/api/contracts/$contractId/adjustments', body: {
      'type': type,
      'reason': reason,
      if (effectiveDate != null) 'effectiveDate': _ymd(effectiveDate),
      if (newEndDate != null) 'newEndDate': _ymd(newEndDate),
      if (newRentPrice != null) 'newRentPrice': newRentPrice,
      if (intendedMoveOutDate != null) 'intendedMoveOutDate': _ymd(intendedMoveOutDate),
      if (clause != null) 'metadata': jsonEncode({'clause': clause}),
      'applyToCurrentContracts': false,
    });
    return ContractAppendixResult.fromJson(data as Map<String, dynamic>);
  }

  /// Tương thích cũ: thêm phụ lục với body thô.
  static Future<ContractAppendixResult> addAppendix(int contractId, Map<String, dynamic> body) async {
    final data = await ApiClient.post('/api/contracts/$contractId/adjustments', body: body);
    return ContractAppendixResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC69: Ghi nhận thu cọc (số tiền, ngày thu, phương thức) — POST /api/contracts/{id}/deposit/collect.
  /// Hợp đồng DRAFT sẽ được kích hoạt (ACTIVE) và phòng chuyển sang RENTED trong cùng giao dịch.
  static Future<ContractResult> collectDeposit(
    int contractId, {
    double? amount,
    DateTime? collectedDate,
    String paymentMethod = 'CASH',
    String? note,
  }) async {
    final data = await ApiClient.post('/api/contracts/$contractId/deposit/collect', body: {
      if (amount != null) 'amount': amount,
      if (collectedDate != null) 'collectedDate': _ymd(collectedDate),
      'paymentMethod': paymentMethod,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
    return ContractResult.fromJson(data as Map<String, dynamic>);
  }

  // Ghi chú UC69: hoàn cọc / khấu trừ cọc không có endpoint riêng; chúng được thực hiện
  // trong luồng Tất toán (SettlementService) để trừ nợ, hư hỏng và hoàn phần còn lại.

  /// UC67: Hủy hợp đồng (lý do bắt buộc) — POST /api/contracts/{id}/cancel?reason=
  static Future<ContractResult> cancel(int contractId, {required String reason}) async {
    final data = await ApiClient.post(
      '/api/contracts/$contractId/cancel',
      params: {'reason': reason},
    );
    return ContractResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC65/UC66: Phụ lục và lịch sử (bao gồm thu cọc, tệp đính kèm).
  static Future<PageResponse<ContractAppendixResult>> getAppendices(int contractId, {int page = 0, int size = 50}) async {
    final data = await ApiClient.get('/api/contracts/$contractId/appendices', params: {
      'page': page,
      'size': size,
    });
    return PageResponse.fromJson(data as Map<String, dynamic>, ContractAppendixResult.fromJson);
  }

  /// Tải toàn bộ phụ lục (qua nhiều trang).
  static Future<List<ContractAppendixResult>> getAllAppendices(int contractId) async {
    final all = <ContractAppendixResult>[];
    var page = 0;
    while (true) {
      final res = await getAppendices(contractId, page: page, size: 50);
      all.addAll(res.content);
      page++;
      if (page >= res.totalPages || res.content.isEmpty) break;
    }
    return all;
  }

  /// UC65: Hóa đơn & lịch sử thanh toán liên quan — GET /api/contracts/{id}/invoices
  static Future<List<ContractInvoiceSummary>> listInvoices(int contractId) async {
    final data = await ApiClient.get('/api/contracts/$contractId/invoices');
    if (data is List) {
      return data.map((e) => ContractInvoiceSummary.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// US63.3: Đính kèm bản scan/mẫu hợp đồng — POST /api/contracts/{id}/attachments
  static Future<ContractAppendixResult> addAttachment(int contractId, {required String fileName, required String base64Data}) async {
    final data = await ApiClient.post('/api/contracts/$contractId/attachments', body: {
      'fileName': fileName,
      'base64Data': base64Data,
    });
    return ContractAppendixResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC68: Đường dẫn tải PDF (dùng với MediaHelper.downloadAndOpen).
  static String pdfEndpoint(int contractId) => '/api/contracts/$contractId/pdf';
}
