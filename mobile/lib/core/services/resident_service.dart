import '../network/api_client.dart';
import 'motel_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers parse JSON an toàn (backend trả BigDecimal dạng số, ngày dạng chuỗi ISO)
// ─────────────────────────────────────────────────────────────────────────────

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

double? _toDoubleOrNull(dynamic v) => v == null ? null : _toDouble(v);

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

int? _toIntOrNull(dynamic v) => v == null ? null : _toInt(v);

String? _str(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

/// Nhận "2026-03-01", "2026-03-01T10:00:00", "2026-03-01T10:00:00+07:00"
/// hoặc mảng [2026, 3, 1] (Jackson mặc định) và trả về DateTime.
DateTime? parseApiDate(dynamic v) {
  if (v == null) return null;
  if (v is List && v.length >= 3) {
    return DateTime(_toInt(v[0]), _toInt(v[1]), _toInt(v[2]),
        v.length > 3 ? _toInt(v[3]) : 0, v.length > 4 ? _toInt(v[4]) : 0);
  }
  final s = v.toString();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s)?.toLocal();
}

/// Định dạng ngày gửi lên API: yyyy-MM-dd.
String formatApiDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

List<T> _list<T>(dynamic v, T Function(Map<String, dynamic>) f) =>
    (v as List<dynamic>? ?? const [])
        .map((e) => f(Map<String, dynamic>.from(e as Map)))
        .toList();

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

/// Trang kết quả phân trang của module Khách thuê.
/// Backend trả khóa `page` (không phải `number`), nên module dùng parser riêng.
class ResidentPage<T> {
  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  const ResidentPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  bool get hasMore => page + 1 < totalPages;

  factory ResidentPage.fromJson(
      Map<String, dynamic> json, T Function(Map<String, dynamic>) f) {
    final content = _list(json['content'], f);
    return ResidentPage(
      content: content,
      page: _toInt(json['page'] ?? json['number']),
      size: _toInt(json['size'] ?? content.length),
      totalElements: _toInt(json['totalElements'] ?? content.length),
      totalPages: _toInt(json['totalPages'] ?? 1),
    );
  }
}

class ResidentResult {
  final String userId;
  final String fullName;
  final String phone;
  final String? email;
  final String? idCardNumber;
  final String status; // "ACTIVE" | "INACTIVE" | "LOCKED" | "PENDING"
  final String? idCardFrontUrl;
  final String? idCardBackUrl;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? gender; // MALE | FEMALE | OTHER
  final String? notes;

  ResidentResult({
    required this.userId,
    required this.fullName,
    required this.phone,
    this.email,
    this.idCardNumber,
    required this.status,
    this.idCardFrontUrl,
    this.idCardBackUrl,
    this.avatarUrl,
    this.dateOfBirth,
    this.gender,
    this.notes,
  });

  bool get active => status == 'ACTIVE';

  factory ResidentResult.fromJson(Map<String, dynamic> json) {
    return ResidentResult(
      userId: (json['userId'] ?? json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: _str(json['email']),
      idCardNumber: _str(json['idCardNumber']),
      status: (json['status'] ??
              (json['active'] == false ? 'INACTIVE' : 'ACTIVE'))
          .toString(),
      idCardFrontUrl: _str(json['idCardFrontUrl']),
      idCardBackUrl: _str(json['idCardBackUrl']),
      avatarUrl: _str(json['avatarUrl']),
      dateOfBirth: parseApiDate(json['dateOfBirth']),
      gender: _str(json['gender']),
      notes: _str(json['notes']),
    );
  }
}

/// UC50: một dòng trong danh sách khách thuê.
class ResidentSummary {
  final String userId;
  final String fullName;
  final String phone;
  final String? email;
  final String accountStatus;
  final String? avatarUrl;
  final int? contractId;
  final String? contractStatus;
  final String? roomNumber;
  final String? motelName;

  /// LIVING | PENDING | NO_CONTRACT | FORMER
  final String residencyStatus;
  final double debtAmount;
  final int unpaidInvoiceCount;

  const ResidentSummary({
    required this.userId,
    required this.fullName,
    required this.phone,
    this.email,
    required this.accountStatus,
    this.avatarUrl,
    this.contractId,
    this.contractStatus,
    this.roomNumber,
    this.motelName,
    required this.residencyStatus,
    required this.debtAmount,
    required this.unpaidInvoiceCount,
  });

  bool get hasDebt => debtAmount > 0;
  bool get accountActive => accountStatus == 'ACTIVE';

  factory ResidentSummary.fromJson(Map<String, dynamic> json) {
    return ResidentSummary(
      userId: (json['userId'] ?? json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: _str(json['email']),
      accountStatus: (json['accountStatus'] ?? 'ACTIVE').toString(),
      avatarUrl: _str(json['avatarUrl']),
      contractId: _toIntOrNull(json['contractId']),
      contractStatus: _str(json['contractStatus']),
      roomNumber: _str(json['roomNumber']),
      motelName: _str(json['motelName']),
      residencyStatus: (json['residencyStatus'] ?? 'NO_CONTRACT').toString(),
      debtAmount: _toDouble(json['debtAmount']),
      unpaidInvoiceCount: _toInt(json['unpaidInvoiceCount']),
    );
  }
}

/// UC52: khách đã trả phòng (một dòng = lần ở gần nhất).
class ResidentHistoryItem {
  final String userId;
  final String fullName;
  final String phone;
  final String accountStatus;
  final int contractId;
  final String contractStatus; // LIQUIDATED | CANCELED
  final String? roomNumber;
  final String? motelName;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final int stayDays;
  final double depositAmount;
  final String? depositStatus;
  final double? settlementTotal;
  final double? settlementPaid;
  final String? settlementStatus;
  final double remainingDebt;
  final String? endReason;

  const ResidentHistoryItem({
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.accountStatus,
    required this.contractId,
    required this.contractStatus,
    this.roomNumber,
    this.motelName,
    this.checkInDate,
    this.checkOutDate,
    required this.stayDays,
    required this.depositAmount,
    this.depositStatus,
    this.settlementTotal,
    this.settlementPaid,
    this.settlementStatus,
    required this.remainingDebt,
    this.endReason,
  });

  factory ResidentHistoryItem.fromJson(Map<String, dynamic> json) {
    return ResidentHistoryItem(
      userId: (json['userId'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      accountStatus: (json['accountStatus'] ?? '').toString(),
      contractId: _toInt(json['contractId']),
      contractStatus: (json['contractStatus'] ?? '').toString(),
      roomNumber: _str(json['roomNumber']),
      motelName: _str(json['motelName']),
      checkInDate: parseApiDate(json['checkInDate']),
      checkOutDate: parseApiDate(json['checkOutDate']),
      stayDays: _toInt(json['stayDays']),
      depositAmount: _toDouble(json['depositAmount']),
      depositStatus: _str(json['depositStatus']),
      settlementTotal: _toDoubleOrNull(json['settlementTotal']),
      settlementPaid: _toDoubleOrNull(json['settlementPaid']),
      settlementStatus: _str(json['settlementStatus']),
      remainingDebt: _toDouble(json['remainingDebt']),
      endReason: _str(json['endReason']),
    );
  }
}

class ResidentContractItem {
  final int id;
  final String status;
  final String? roomNumber;
  final String? motelName;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? moveOutDate;
  final double rentPrice;
  final double depositAmount;
  final String? depositStatus;
  final bool primary;

  const ResidentContractItem({
    required this.id,
    required this.status,
    this.roomNumber,
    this.motelName,
    this.startDate,
    this.endDate,
    this.moveOutDate,
    required this.rentPrice,
    required this.depositAmount,
    this.depositStatus,
    required this.primary,
  });

  factory ResidentContractItem.fromJson(Map<String, dynamic> json) {
    return ResidentContractItem(
      id: _toInt(json['id']),
      status: (json['status'] ?? '').toString(),
      roomNumber: _str(json['roomNumber']),
      motelName: _str(json['motelName']),
      startDate: parseApiDate(json['startDate']),
      endDate: parseApiDate(json['endDate']),
      moveOutDate: parseApiDate(json['moveOutDate']),
      rentPrice: _toDouble(json['rentPrice']),
      depositAmount: _toDouble(json['depositAmount']),
      depositStatus: _str(json['depositStatus']),
      primary: json['primary'] == true,
    );
  }
}

class ResidentInvoiceItem {
  final int id;
  final int contractId;
  final String? roomNumber;
  final DateTime? billingMonth;
  final DateTime? dueDate;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String status; // PENDING | PARTIAL | PAID | VOID
  final String? invoiceType; // MONTHLY | SETTLEMENT

  const ResidentInvoiceItem({
    required this.id,
    required this.contractId,
    this.roomNumber,
    this.billingMonth,
    this.dueDate,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
    this.invoiceType,
  });

  bool get unpaid => status == 'PENDING' || status == 'PARTIAL';

  factory ResidentInvoiceItem.fromJson(Map<String, dynamic> json) {
    return ResidentInvoiceItem(
      id: _toInt(json['id']),
      contractId: _toInt(json['contractId']),
      roomNumber: _str(json['roomNumber']),
      billingMonth: parseApiDate(json['billingMonth']),
      dueDate: parseApiDate(json['dueDate']),
      totalAmount: _toDouble(json['totalAmount']),
      paidAmount: _toDouble(json['paidAmount']),
      remainingAmount: _toDouble(json['remainingAmount']),
      status: (json['status'] ?? '').toString(),
      invoiceType: _str(json['invoiceType']),
    );
  }
}

class ResidentMaintenanceItem {
  final int id;
  final String? roomNumber;
  final String category;
  final String description;
  final String status;
  final String? priority;
  final DateTime? createdAt;
  final DateTime? completedAt;

  const ResidentMaintenanceItem({
    required this.id,
    this.roomNumber,
    required this.category,
    required this.description,
    required this.status,
    this.priority,
    this.createdAt,
    this.completedAt,
  });

  factory ResidentMaintenanceItem.fromJson(Map<String, dynamic> json) {
    return ResidentMaintenanceItem(
      id: _toInt(json['id']),
      roomNumber: _str(json['roomNumber']),
      category: (json['category'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      priority: _str(json['priority']),
      createdAt: parseApiDate(json['createdAt']),
      completedAt: parseApiDate(json['completedAt']),
    );
  }
}

class ResidentActivityItem {
  final String action;
  final String? oldValue;
  final String? newValue;
  final String? field;
  final DateTime? timestamp;

  const ResidentActivityItem({
    required this.action,
    this.oldValue,
    this.newValue,
    this.field,
    this.timestamp,
  });

  factory ResidentActivityItem.fromJson(Map<String, dynamic> json) {
    final meta = _str(json['metadata']);
    String? field;
    if (meta != null) {
      final m = RegExp(r'"field"\s*:\s*"([^"]+)"').firstMatch(meta);
      field = m?.group(1);
    }
    return ResidentActivityItem(
      action: (json['action'] ?? '').toString(),
      oldValue: _str(json['oldValue']),
      newValue: _str(json['newValue']),
      field: field,
      timestamp: parseApiDate(json['timestamp']),
    );
  }
}

/// UC51: chi tiết tổng hợp của một khách thuê.
class ResidentOverview {
  final ResidentResult profile;
  final String residencyStatus;
  final double totalDebt;
  final int unpaidInvoiceCount;
  final bool canDeactivate;
  final String? deactivateBlockReason;
  final List<ResidentContractItem> contracts;
  final List<ResidentInvoiceItem> invoices;
  final List<ResidentMaintenanceItem> maintenanceRequests;
  final List<ResidentActivityItem> activities;

  const ResidentOverview({
    required this.profile,
    required this.residencyStatus,
    required this.totalDebt,
    required this.unpaidInvoiceCount,
    required this.canDeactivate,
    this.deactivateBlockReason,
    required this.contracts,
    required this.invoices,
    required this.maintenanceRequests,
    required this.activities,
  });

  /// Hợp đồng đang ở (ACTIVE / chờ thanh lý) nếu có.
  ResidentContractItem? get currentContract {
    for (final c in contracts) {
      if (c.status == 'ACTIVE' || c.status == 'PENDING_LIQUIDATION') return c;
    }
    return null;
  }

  factory ResidentOverview.fromJson(Map<String, dynamic> json) {
    return ResidentOverview(
      profile: ResidentResult.fromJson(
          Map<String, dynamic>.from(json['profile'] as Map? ?? const {})),
      residencyStatus: (json['residencyStatus'] ?? 'NO_CONTRACT').toString(),
      totalDebt: _toDouble(json['totalDebt']),
      unpaidInvoiceCount: _toInt(json['unpaidInvoiceCount']),
      canDeactivate: json['canDeactivate'] == true,
      deactivateBlockReason: _str(json['deactivateBlockReason']),
      contracts: _list(json['contracts'], ResidentContractItem.fromJson),
      invoices: _list(json['invoices'], ResidentInvoiceItem.fromJson),
      maintenanceRequests:
          _list(json['maintenanceRequests'], ResidentMaintenanceItem.fromJson),
      activities: _list(json['activities'], ResidentActivityItem.fromJson),
    );
  }
}

/// UC49: hợp đồng đang mở có thể gắn khách mới vào.
class LinkableContract {
  final int id;
  final String status;
  final String? roomNumber;
  final String? motelName;
  final String? primaryResidentName;

  const LinkableContract({
    required this.id,
    required this.status,
    this.roomNumber,
    this.motelName,
    this.primaryResidentName,
  });

  String get label {
    final room = roomNumber != null ? 'Phòng $roomNumber' : 'HĐ #$id';
    final motel = motelName != null ? ' · $motelName' : '';
    return '$room$motel';
  }

  factory LinkableContract.fromJson(Map<String, dynamic> json) {
    return LinkableContract(
      id: _toInt(json['id']),
      status: (json['status'] ?? '').toString(),
      roomNumber: _str(json['roomNumber']),
      motelName: _str(json['motelName']),
      primaryResidentName: _str(json['primaryResidentName']),
    );
  }
}

/// Kết quả OCR CCCD dùng để điền sẵn form.
class IdCardOcrResult {
  final String fullName;
  final String idCardNumber;
  final DateTime? dateOfBirth;
  final String? address;

  const IdCardOcrResult({
    required this.fullName,
    required this.idCardNumber,
    this.dateOfBirth,
    this.address,
  });

  bool get isEmpty => fullName.isEmpty && idCardNumber.isEmpty && dateOfBirth == null;

  factory IdCardOcrResult.fromJson(Map<String, dynamic> map) {
    final rawId = (map['idNumber'] ?? map['idCardNumber'] ?? '').toString();
    return IdCardOcrResult(
      fullName: (map['fullName'] ?? '').toString().trim(),
      idCardNumber: rawId.replaceAll(RegExp(r'[^0-9]'), ''),
      dateOfBirth: _parseOcrDate(map['dateOfBirth']),
      address: _str(map['address']),
    );
  }

  static DateTime? _parseOcrDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;
    final m = RegExp(r'^(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})$').firstMatch(s);
    if (m != null) {
      return DateTime(int.parse(m.group(3)!), int.parse(m.group(2)!),
          int.parse(m.group(1)!));
    }
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kiểm tra dữ liệu form (BR49.2, BR49.3, BR53.3)
// ─────────────────────────────────────────────────────────────────────────────

class ResidentValidators {
  ResidentValidators._();

  static final RegExp _phone = RegExp(r'^(84|0)(3|5|7|8|9)[0-9]{8}$');
  static final RegExp _cccd = RegExp(r'^[0-9]{12}$');
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? fullName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập họ và tên';
    if (v.trim().length < 2) return 'Họ tên quá ngắn';
    return null;
  }

  static String? phone(String? v) {
    final s = (v ?? '').replaceAll(RegExp(r'\s'), '');
    if (s.isEmpty) return 'Vui lòng nhập số điện thoại';
    if (!_phone.hasMatch(s)) {
      return 'Số điện thoại chưa đúng (10 số, bắt đầu bằng 03, 05, 07, 08, 09)';
    }
    return null;
  }

  static String? idCard(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Vui lòng nhập số CCCD';
    if (!_cccd.hasMatch(s)) return 'Số CCCD phải gồm đúng 12 chữ số';
    return null;
  }

  static String? email(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    if (!_email.hasMatch(s)) return 'Email chưa đúng định dạng';
    return null;
  }

  static String? dateOfBirth(DateTime? d, {DateTime? now}) {
    if (d == null) return null;
    final today = now ?? DateTime.now();
    if (d.isAfter(today)) return 'Ngày sinh không được ở tương lai';
    if (today.year - d.year > 120) return 'Ngày sinh chưa hợp lệ';
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// API
// ─────────────────────────────────────────────────────────────────────────────

typedef ResidentApiService = ResidentService;

class ResidentService {
  /// Bộ lọc danh sách khách (UC50).
  static const filterAll = 'ALL';
  static const filterLiving = 'LIVING';
  static const filterPending = 'PENDING';
  static const filterFormer = 'FORMER';
  static const filterDebt = 'DEBT';
  static const filterInactive = 'INACTIVE';

  /// UC50 (cũ): List residents — GET /api/residents. Giữ cho màn Hợp đồng dùng.
  static Future<PageResponse<ResidentResult>> list({int page = 0, int size = 50}) async {
    final data = await ApiClient.get('/api/residents', params: {
      'page': page,
      'size': size,
    });
    return PageResponse.fromJson(data as Map<String, dynamic>, ResidentResult.fromJson);
  }

  /// UC50: tìm theo tên/SĐT, lọc trạng thái, phân trang — GET /api/residents/search
  static Future<ResidentPage<ResidentSummary>> search({
    String query = '',
    String status = filterAll,
    int page = 0,
    int size = 20,
  }) async {
    final data = await ApiClient.get('/api/residents/search', params: {
      'q': query.trim(),
      'status': status,
      'page': page,
      'size': size,
    });
    return ResidentPage.fromJson(
        Map<String, dynamic>.from(data as Map), ResidentSummary.fromJson);
  }

  /// UC52: khách đã trả phòng, lọc theo ngày trả — GET /api/residents/history
  static Future<ResidentPage<ResidentHistoryItem>> history({
    String query = '',
    DateTime? from,
    DateTime? to,
    int page = 0,
    int size = 20,
  }) async {
    final data = await ApiClient.get('/api/residents/history', params: {
      'q': query.trim(),
      if (from != null) 'from': formatApiDate(from),
      if (to != null) 'to': formatApiDate(to),
      'page': page,
      'size': size,
    });
    return ResidentPage.fromJson(
        Map<String, dynamic>.from(data as Map), ResidentHistoryItem.fromJson);
  }

  /// UC51: Get resident by ID — GET /api/residents/{id}
  static Future<ResidentResult> get(String residentId) async {
    final data = await ApiClient.get('/api/residents/$residentId');
    return ResidentResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC51: chi tiết tổng hợp — GET /api/residents/{id}/overview
  static Future<ResidentOverview> overview(String residentId) async {
    final data = await ApiClient.get('/api/residents/$residentId/overview');
    return ResidentOverview.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// UC49: hợp đồng có thể gắn khách — GET /api/residents/linkable-contracts
  static Future<List<LinkableContract>> linkableContracts() async {
    final data = await ApiClient.get('/api/residents/linkable-contracts');
    return _list(data, LinkableContract.fromJson);
  }

  /// UC49: Create resident — POST /api/residents
  static Future<ResidentResult> create({
    required String fullName,
    required String phone,
    required String idCardNumber,
    String? email,
    String? idCardFrontUrl,
    String? idCardBackUrl,
    DateTime? dateOfBirth,
    String? gender,
    String? notes,
    String? avatarUrl,
    int? contractId,
  }) async {
    final data = await ApiClient.post('/api/residents', body: buildCreateBody(
      fullName: fullName,
      phone: phone,
      idCardNumber: idCardNumber,
      email: email,
      idCardFrontUrl: idCardFrontUrl,
      idCardBackUrl: idCardBackUrl,
      dateOfBirth: dateOfBirth,
      gender: gender,
      notes: notes,
      avatarUrl: avatarUrl,
      contractId: contractId,
    ));
    return ResidentResult.fromJson(data as Map<String, dynamic>);
  }

  /// Body JSON cho UC49 (tách riêng để kiểm thử).
  static Map<String, dynamic> buildCreateBody({
    required String fullName,
    required String phone,
    required String idCardNumber,
    String? email,
    String? idCardFrontUrl,
    String? idCardBackUrl,
    DateTime? dateOfBirth,
    String? gender,
    String? notes,
    String? avatarUrl,
    int? contractId,
  }) {
    bool has(String? s) => s != null && s.trim().isNotEmpty;
    return {
      'fullName': fullName.trim(),
      'phone': phone.replaceAll(RegExp(r'\s'), ''),
      'idCardNumber': idCardNumber.trim(),
      if (has(email)) 'email': email!.trim(),
      if (has(idCardFrontUrl)) 'idCardFrontUrl': idCardFrontUrl,
      if (has(idCardBackUrl)) 'idCardBackUrl': idCardBackUrl,
      if (dateOfBirth != null) 'dateOfBirth': formatApiDate(dateOfBirth),
      if (has(gender)) 'gender': gender,
      if (has(notes)) 'notes': notes!.trim(),
      if (has(avatarUrl)) 'avatarUrl': avatarUrl,
      if (contractId != null) 'contractId': contractId,
    };
  }

  /// UC53: Update resident — PATCH /api/residents/{id}
  static Future<ResidentResult> update(String residentId, Map<String, dynamic> body) async {
    final data = await ApiClient.patch('/api/residents/$residentId', body: body);
    return ResidentResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC53: chỉ gửi những trường hành chính được phép sửa và thực sự thay đổi.
  /// Họ tên và CCCD không bao giờ được gửi từ màn này (cần yêu cầu chỉnh sửa).
  static Map<String, dynamic> buildUpdateBody({
    required ResidentResult original,
    required String phone,
    required String email,
    required String notes,
    DateTime? dateOfBirth,
    String? gender,
    String? avatarUrl,
  }) {
    final body = <String, dynamic>{};
    final p = phone.replaceAll(RegExp(r'\s'), '');
    if (p != original.phone) body['phone'] = p;
    if (email.trim() != (original.email ?? '')) body['email'] = email.trim();
    if (notes.trim() != (original.notes ?? '')) body['notes'] = notes.trim();
    if (dateOfBirth != null &&
        (original.dateOfBirth == null ||
            formatApiDate(dateOfBirth) != formatApiDate(original.dateOfBirth!))) {
      body['dateOfBirth'] = formatApiDate(dateOfBirth);
    }
    if (gender != null && gender != original.gender) body['gender'] = gender;
    if (avatarUrl != null && avatarUrl != original.avatarUrl) body['avatarUrl'] = avatarUrl;
    return body;
  }

  /// UC54: Deactivate resident — POST /api/residents/{id}/deactivate
  static Future<void> deactivate(String residentId) async {
    await ApiClient.post('/api/residents/$residentId/deactivate');
  }

  /// OCR CCCD — POST /api/residents/ocr/idcard
  static Future<IdCardOcrResult> ocrIdCard({
    required String base64Image,
    String mimeType = 'image/jpeg',
  }) async {
    final data = await ApiClient.post('/api/residents/ocr/idcard', body: {
      'base64Image': base64Image,
      'mimeType': mimeType,
    });
    return IdCardOcrResult.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// OCR CCCD (giữ API cũ) — trả về map fullName/idCardNumber.
  static Future<Map<String, String>> ocrCccd({
    required String base64Image,
    required String mimeType,
  }) async {
    final r = await ocrIdCard(base64Image: base64Image, mimeType: mimeType);
    return {'fullName': r.fullName, 'idCardNumber': r.idCardNumber};
  }
}
