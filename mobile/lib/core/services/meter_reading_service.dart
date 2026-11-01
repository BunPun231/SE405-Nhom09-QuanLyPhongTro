import 'dart:async';

import '../network/api_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Module IX – Chỉ số điện/nước (UC70, UC71, UC72)
// Service + model riêng cho chỉ số. Các hàm chỉ số cũ trong invoice_service.dart
// được giữ nguyên để không ảnh hưởng module hóa đơn.
// ─────────────────────────────────────────────────────────────────────────────

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int _toInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

/// Trạng thái bản ghi chỉ số (BR70.6).
class MeterStatus {
  MeterStatus._();
  static const pending = 'PENDING';
  static const approved = 'APPROVED';
  static const rejected = 'REJECTED';

  /// Bản ghi đang chờ Quản lý duyệt (backend cũ có thể trả SUBMITTED).
  static bool isPending(String? s) => s == pending || s == 'SUBMITTED';

  static String label(String? s) {
    switch (s) {
      case approved:
        return 'Đã duyệt';
      case rejected:
        return 'Bị từ chối';
      case pending:
      case 'SUBMITTED':
        return 'Chờ duyệt';
      default:
        return 'Chưa ghi';
    }
  }
}

/// Một bản ghi chỉ số (khớp `MeterReadingResult` của backend).
class MeterReading {
  final int id;
  final int roomId;
  final int serviceId;
  final String serviceName;

  /// Ngày đầu tháng của kỳ hóa đơn, dạng `yyyy-MM-dd`.
  final String billingMonth;
  final double oldReading;
  final double? newReading;
  final double? _consumption;
  final String status;
  final String? imageUrl;

  /// Độ tin cậy OCR, đã chuẩn hóa về thang 0–100 (null nếu không qua OCR).
  final double? ocrConfidence;
  final String? rejectReason;
  final DateTime? createdAt;

  MeterReading({
    required this.id,
    required this.roomId,
    required this.serviceId,
    required this.serviceName,
    required this.billingMonth,
    required this.oldReading,
    this.newReading,
    double? consumption,
    required this.status,
    this.imageUrl,
    this.ocrConfidence,
    this.rejectReason,
    this.createdAt,
  }) : _consumption = consumption;

  factory MeterReading.fromJson(Map<String, dynamic> json) {
    final url = json['readingImageUrl'] ?? json['imageUrl'];
    final reason = json['rejectReason'];
    return MeterReading(
      id: _toInt(json['id']),
      roomId: _toInt(json['roomId']),
      serviceId: _toInt(json['serviceId']),
      serviceName: (json['serviceName'] ?? '').toString(),
      billingMonth: (json['billingMonth'] ?? '').toString(),
      oldReading: _toDouble(json['oldReading']) ?? 0,
      newReading: _toDouble(json['newReading']),
      consumption: _toDouble(json['consumption']),
      status: (json['status'] ?? MeterStatus.pending).toString(),
      imageUrl: (url == null || url.toString().isEmpty) ? null : url.toString(),
      ocrConfidence: json['ocrConfidence'] == null
          ? null
          : MeterRules.normalizeConfidence(_toDouble(json['ocrConfidence'])),
      rejectReason:
          (reason == null || reason.toString().trim().isEmpty) ? null : reason.toString(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
    );
  }

  /// Mức tiêu thụ = mới − cũ (BR72.4). Backend có thể trả null ngay sau khi tạo
  /// (cột tính toán), nên tự tính lại khi cần.
  double? get consumption =>
      _consumption ??
      (newReading == null ? null : MeterRules.consumption(oldReading, newReading!));

  /// Khóa tháng `yyyy-MM`.
  String get monthKey => billingMonth.length >= 7 ? billingMonth.substring(0, 7) : billingMonth;

  bool get isPending => MeterStatus.isPending(status);
  bool get isApproved => status == MeterStatus.approved;
  bool get isRejected => status == MeterStatus.rejected;

  /// Đồng hồ được thay/reset: số mới nhỏ hơn số cũ (BR72.7).
  bool get isMeterReset => newReading != null && newReading! < oldReading;
}

/// Gợi ý từ OCR (UC71). Không bao giờ được tự lưu (BR71.6).
class OcrSuggestion {
  final double value;

  /// Độ tin cậy 0–100.
  final double confidence;

  /// Chỉ số cũ hệ thống sẽ dùng (backend tự xác định).
  final double? oldReading;

  OcrSuggestion({required this.value, required this.confidence, this.oldReading});

  factory OcrSuggestion.fromJson(Map<String, dynamic> json) {
    return OcrSuggestion(
      value: _toDouble(json['newReading']) ?? 0,
      confidence: MeterRules.normalizeConfidence(_toDouble(json['ocrConfidence'])),
      oldReading: _toDouble(json['oldReading']),
    );
  }

  /// Dưới ngưỡng 90%: phải để người dùng xác nhận/kiểm tra kỹ.
  bool get needsReview => MeterRules.needsReview(confidence);

  /// Dưới 70%: cảnh báo đỏ theo BR71.4.
  bool get isLowConfidence => MeterRules.isLowConfidence(confidence);
}

/// Điểm dữ liệu biểu đồ tiêu thụ.
class ConsumptionPoint {
  final String monthKey;
  final double consumption;
  final bool meterReset;
  ConsumptionPoint(this.monthKey, this.consumption, {this.meterReset = false});
}

/// OCR quá 5 giây (BR71.2) — chuyển sang nhập tay.
class OcrTimeoutException implements Exception {
  @override
  String toString() => 'Nhận diện quá 5 giây. Vui lòng nhập chỉ số bằng tay.';
}

/// Quy tắc nghiệp vụ thuần (không gọi mạng) để dễ kiểm thử.
class MeterRules {
  MeterRules._();

  /// Ngưỡng bắt buộc người dùng xác nhận kết quả OCR.
  static const double reviewThreshold = 90;

  /// Ngưỡng cảnh báo đỏ "Kết quả có thể không chính xác" (BR71.4).
  static const double lowConfidenceThreshold = 70;

  /// Giới hạn thời gian OCR (BR71.2).
  static const Duration ocrTimeout = Duration(seconds: 5);

  /// Ngưỡng tiêu thụ bất thường so với trung bình 3 tháng (BR70.7).
  static const double anomalyFactor = 1.3;

  /// Kích thước ảnh tối thiểu (BR71.1).
  static const int minImageLongSide = 640;
  static const int minImageShortSide = 480;

  /// Backend có thể trả độ tin cậy thang 0–1 hoặc 0–100; chuẩn hóa về 0–100.
  static double normalizeConfidence(double? raw) {
    if (raw == null || raw.isNaN || raw < 0) return 0;
    final v = raw <= 1 ? raw * 100 : raw;
    return v > 100 ? 100 : v;
  }

  static bool needsReview(double confidence) => confidence < reviewThreshold;
  static bool isLowConfidence(double confidence) => confidence < lowConfidenceThreshold;

  /// Lọc ký tự nhiễu/đơn vị (kWh, m³…) và lấy chuỗi số đầu tiên (BR71.3).
  static double? sanitizeReading(String? raw) {
    if (raw == null) return null;
    final m = RegExp(r'\d+(?:[.,]\d+)?').firstMatch(raw.replaceAll(' ', ''));
    if (m == null) return null;
    return double.tryParse(m.group(0)!.replaceAll(',', '.'));
  }

  /// Phân tích chuỗi người dùng gõ. Trả null nếu không hợp lệ.
  static double? parseInput(String text) {
    final t = text.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    final v = double.tryParse(t);
    if (v == null || v.isNaN || v.isInfinite || v < 0) return null;
    return v;
  }

  /// Kiểm tra chỉ số mới (BR70.3). Trả thông báo lỗi tiếng Việt, hoặc null nếu hợp lệ.
  static String? validateNewReading(double? oldReading, String newText) {
    if (newText.trim().isEmpty) return 'Vui lòng nhập chỉ số mới';
    final v = parseInput(newText);
    if (v == null) return 'Chỉ số không hợp lệ';
    if (oldReading != null && v < oldReading) {
      return 'Chỉ số mới phải lớn hơn hoặc bằng chỉ số cũ (${formatReading(oldReading)}). '
          'Vui lòng kiểm tra lại đồng hồ.';
    }
    return null;
  }

  static double consumption(double oldReading, double newReading) => newReading - oldReading;

  /// Trung bình tiêu thụ của tối đa [n] kỳ đã duyệt gần nhất trước [beforeMonthKey]
  /// cho cùng phòng + dịch vụ (BR70.5). Null nếu chưa có dữ liệu.
  static double? averageConsumption(
    List<MeterReading> readings, {
    required int roomId,
    required int serviceId,
    required String beforeMonthKey,
    int n = 3,
  }) {
    final past = readings
        .where((r) =>
            r.roomId == roomId &&
            r.serviceId == serviceId &&
            r.isApproved &&
            !r.isMeterReset &&
            r.consumption != null &&
            r.monthKey.compareTo(beforeMonthKey) < 0)
        .toList()
      ..sort((a, b) => b.monthKey.compareTo(a.monthKey));
    if (past.isEmpty) return null;
    final take = past.take(n).toList();
    final sum = take.fold<double>(0, (s, r) => s + r.consumption!);
    return sum / take.length;
  }

  /// Tiêu thụ vượt 130% trung bình (BR70.7).
  static bool isHighConsumption(double? consumption, double? average) {
    if (consumption == null || average == null || average <= 0) return false;
    return consumption > average * anomalyFactor;
  }

  /// Dữ liệu biểu đồ: các kỳ đã duyệt của một dịch vụ, sắp tăng dần theo tháng,
  /// lấy tối đa [maxMonths] tháng gần nhất (BR72.6).
  static List<ConsumptionPoint> buildTrend(
    List<MeterReading> history, {
    int? serviceId,
    int maxMonths = 12,
  }) {
    final list = history
        .where((r) => r.isApproved && (serviceId == null || r.serviceId == serviceId))
        .toList()
      ..sort((a, b) => a.monthKey.compareTo(b.monthKey));
    final tail = list.length > maxMonths ? list.sublist(list.length - maxMonths) : list;
    return tail
        .map((r) => ConsumptionPoint(
              r.monthKey,
              (r.consumption ?? 0) < 0 ? 0 : (r.consumption ?? 0),
              meterReset: r.isMeterReset,
            ))
        .toList();
  }

  /// Lịch sử chính thức: chỉ APPROVED, mới nhất trước (BR72.2, BR72.3).
  static List<MeterReading> officialHistory(List<MeterReading> readings) {
    return readings.where((r) => r.isApproved).toList()
      ..sort((a, b) => b.monthKey.compareTo(a.monthKey));
  }

  /// Ảnh đủ độ phân giải 640×480 (theo cả hai chiều xoay).
  static bool isImageResolutionOk(int width, int height) {
    final long = width > height ? width : height;
    final short = width > height ? height : width;
    return long >= minImageLongSide && short >= minImageShortSide;
  }

  static bool isElectric(String serviceName) {
    final n = serviceName.toLowerCase();
    return n.contains('điện') || n.contains('dien') || n.contains('electric');
  }

  static String mimeTypeFor(String fileName) {
    final n = fileName.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  /// `2026-06-01` hoặc `2026-06` → `Tháng 6/2026`.
  static String monthLabel(String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length < 2) return monthKey;
    return 'Tháng ${int.tryParse(parts[1]) ?? parts[1]}/${parts[0]}';
  }

  /// `2026-06` → `T6/26` (nhãn trục biểu đồ).
  static String shortMonthLabel(String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length < 2) return monthKey;
    final y = parts[0].length == 4 ? parts[0].substring(2) : parts[0];
    return 'T${int.tryParse(parts[1]) ?? parts[1]}/$y';
  }

  static String monthKeyOf(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

  /// Định dạng số chỉ số: bỏ phần thập phân thừa, nhóm hàng nghìn bằng dấu chấm.
  static String formatReading(double? v) {
    if (v == null) return '—';
    final isInt = v == v.roundToDouble();
    final fixed = isInt ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    final parts = fixed.split('.');
    final neg = parts[0].startsWith('-');
    final digits = neg ? parts[0].substring(1) : parts[0];
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    return '${neg ? '-' : ''}$buf${parts.length > 1 ? ',${parts[1]}' : ''}';
  }
}

/// Gọi API `/api/v1/meter-readings`.
class MeterReadingApi {
  MeterReadingApi._();

  static const _base = '/api/v1/meter-readings';

  static List<MeterReading> _parseList(dynamic data) {
    final list = data is List
        ? data
        : (data is Map<String, dynamic> ? (data['content'] as List<dynamic>? ?? const []) : const []);
    return list.map((e) => MeterReading.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// UC70/UC72: danh sách chỉ số (lọc theo phòng/trạng thái).
  static Future<List<MeterReading>> list({int? roomId, String? status, int page = 0, int size = 500}) async {
    final data = await ApiClient.get(_base, params: {
      if (roomId != null) 'roomId': roomId,
      if (status != null) 'status': status,
      'page': page,
      'size': size,
    });
    return _parseList(data);
  }

  /// UC70: chỉ số cũ hệ thống sẽ dùng cho lần gửi tiếp theo.
  static Future<double?> oldReading({required int roomId, required int serviceId}) async {
    final data = await ApiClient.get('$_base/rooms/$roomId/old-reading', params: {'serviceId': serviceId});
    if (data is Map) return _toDouble(data['oldReading']);
    return null;
  }

  /// UC70: gửi chỉ số kèm ảnh đồng hồ (base64). Khách thuê → PENDING.
  static Future<MeterReading> submit({
    required int roomId,
    required int serviceId,
    required String billingMonth,
    required double newReading,
    String? base64Image,
    String? mimeType,
  }) async {
    final data = await ApiClient.post(_base, body: {
      'roomId': roomId,
      'serviceId': serviceId,
      'billingMonth': billingMonth,
      'newReading': newReading,
      if (base64Image != null) 'base64Image': base64Image,
      if (base64Image != null) 'mimeType': mimeType ?? 'image/jpeg',
    });
    return MeterReading.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// UC71: nhận diện số từ ảnh. Quá 5 giây → [OcrTimeoutException].
  static Future<OcrSuggestion> recognize({
    required int roomId,
    required int serviceId,
    required String billingMonth,
    required String base64Image,
    required String mimeType,
    Duration timeout = MeterRules.ocrTimeout,
  }) async {
    try {
      final data = await ApiClient.post('$_base/ocr', body: {
        'roomId': roomId,
        'serviceId': serviceId,
        'billingMonth': billingMonth,
        'base64Image': base64Image,
        'mimeType': mimeType,
      }).timeout(timeout);
      return OcrSuggestion.fromJson(Map<String, dynamic>.from(data as Map));
    } on TimeoutException {
      throw OcrTimeoutException();
    }
  }

  static Future<MeterReading> approve(int id) async {
    final data = await ApiClient.post('$_base/$id/approve');
    return MeterReading.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Backend nhận mảng id thô (`List<Long>`).
  static Future<void> bulkApprove(List<int> ids) async {
    await ApiClient.post('$_base/bulk-approve', body: ids);
  }

  static Future<MeterReading> reject(int id, String reason) async {
    final data = await ApiClient.post('$_base/$id/reject', params: {'reason': reason});
    return MeterReading.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// UC72: lịch sử đã duyệt của phòng, mới nhất trước.
  static Future<List<MeterReading>> history(int roomId) async {
    final data = await ApiClient.get('$_base/rooms/$roomId/history');
    return MeterRules.officialHistory(_parseList(data));
  }
}
