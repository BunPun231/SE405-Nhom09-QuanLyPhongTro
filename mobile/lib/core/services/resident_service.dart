import '../network/api_client.dart';
import 'motel_service.dart';

class ResidentResult {
  final String userId;
  final String fullName;
  final String phone;
  final String? email;
  final String? idCardNumber;
  final String status; // "ACTIVE" | "INACTIVE"
  final String? idCardFrontUrl;
  final String? idCardBackUrl;

  ResidentResult({
    required this.userId,
    required this.fullName,
    required this.phone,
    this.email,
    this.idCardNumber,
    required this.status,
    this.idCardFrontUrl,
    this.idCardBackUrl,
  });

  bool get active => status == 'ACTIVE';

  factory ResidentResult.fromJson(Map<String, dynamic> json) {
    return ResidentResult(
      userId: (json['userId'] ?? json['id'] ?? '').toString(),
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      idCardNumber: json['idCardNumber'],
      status: json['status'] ?? (json['active'] == false ? 'INACTIVE' : 'ACTIVE'),
      idCardFrontUrl: json['idCardFrontUrl'],
      idCardBackUrl: json['idCardBackUrl'],
    );
  }
}

typedef ResidentApiService = ResidentService;

class ResidentService {
  /// UC50: List residents — GET /api/residents
  static Future<PageResponse<ResidentResult>> list({int page = 0, int size = 50}) async {
    final data = await ApiClient.get('/api/residents', params: {
      'page': page,
      'size': size,
    });
    return PageResponse.fromJson(data as Map<String, dynamic>, ResidentResult.fromJson);
  }

  /// UC51: Get resident by ID — GET /api/residents/{id}
  static Future<ResidentResult> get(String residentId) async {
    final data = await ApiClient.get('/api/residents/$residentId');
    return ResidentResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC49: Create resident — POST /api/residents
  static Future<ResidentResult> create({
    required String fullName,
    required String phone,
    required String idCardNumber,
    String? email,
    String? idCardFrontUrl,
    String? idCardBackUrl,
  }) async {
    final data = await ApiClient.post('/api/residents', body: {
      'fullName': fullName,
      'phone': phone,
      'idCardNumber': idCardNumber,
      if (email != null && email.isNotEmpty) 'email': email,
      if (idCardFrontUrl != null) 'idCardFrontUrl': idCardFrontUrl,
      if (idCardBackUrl != null) 'idCardBackUrl': idCardBackUrl,
    });
    return ResidentResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC53: Update resident — PATCH /api/residents/{id}
  static Future<ResidentResult> update(String residentId, Map<String, dynamic> body) async {
    final data = await ApiClient.patch('/api/residents/$residentId', body: body);
    return ResidentResult.fromJson(data as Map<String, dynamic>);
  }

  /// UC54: Deactivate resident — POST /api/residents/{id}/deactivate
  static Future<void> deactivate(String residentId) async {
    await ApiClient.post('/api/residents/$residentId/deactivate');
  }

  /// OCR CCCD — POST /api/residents/ocr/idcard
  static Future<Map<String, String>> ocrCccd({
    required String base64Image,
    required String mimeType,
  }) async {
    final data = await ApiClient.post('/api/residents/ocr/idcard', body: {
      'base64Image': base64Image,
      'mimeType': mimeType,
    });
    final map = data as Map<String, dynamic>;
    return {
      'fullName': (map['fullName'] ?? '').toString(),
      'idCardNumber': (map['idNumber'] ?? map['idCardNumber'] ?? '').toString(),
    };
  }
}
