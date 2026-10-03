import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// ApiClient hoạt động giống hệt api.ts của Frontend:
/// - Attach JWT Bearer token vào Header Authorization
/// - Attach X-Tenant-Id header giống tenantStore
/// - Xử lý 401 → Logout (giống response interceptor)
/// - Parse body: backend trả về { data: T } hoặc raw T
class ApiClient {
  /// URL Backend Spring Boot — giống VITE_API_BASE_URL
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080'; // iOS Simulator / macOS
  }

  static const String _tenantHeader = 'X-Tenant-Id'; // giống VITE_TENANT_HEADER
  static const Duration _timeout = Duration(seconds: 30); // giống axios timeout: 30000

  // Session state (giống authStore + tenantStore của Zustand)
  static String? _accessToken;
  static String? _tenantId;

  // ─── Session Management ────────────────────────────────

  /// Đọc token từ SharedPreferences khi khởi động (giống localStorage.getItem)
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _tenantId = prefs.getString('tenant_id');
  }

  /// Lưu session sau khi login thành công (giống authStore.login)
  static Future<void> setSession({required String accessToken, String? tenantId}) async {
    _accessToken = accessToken;
    _tenantId = tenantId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    if (tenantId != null) {
      await prefs.setString('tenant_id', tenantId);
    } else {
      await prefs.remove('tenant_id');
    }
  }

  /// Xóa session khi đăng xuất (giống authStore.logout)
  static Future<void> logout() async {
    _accessToken = null;
    _tenantId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('tenant_id');
    await prefs.remove('user_role');
    await prefs.remove('user_fullname');
  }

  static String? get accessToken => _accessToken;
  static String? get tenantId => _tenantId;

  // ─── Request Interceptor (Headers) ────────────────────

  /// Giống api.interceptors.request.use — attach Authorization + X-Tenant-Id
  static Map<String, String> _buildHeaders([Map<String, String>? extra]) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      headers[_tenantHeader] = _tenantId!;
    }
    if (extra != null) headers.addAll(extra);
    return headers;
  }

  // ─── Response Interceptor ────────────────────────────

  /// Giống api.interceptors.response.use — 401 → logout, extract error message
  static dynamic _processResponse(http.Response response) {
    final status = response.statusCode;

    if (status == 401) {
      logout(); // clear session
      throw Exception('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
    }

    if (status >= 200 && status < 300) {
      if (response.body.isEmpty) return null;
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      // Backend có thể trả về { data: T, message: ... } hoặc raw T/PageResponse
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded;
    }

    // Giống extractError() của frontend
    String errorMsg = 'Lỗi kết nối máy chủ ($status)';
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        errorMsg = decoded['message'] ?? decoded['error'] ?? errorMsg;
      }
    } catch (_) {}
    throw Exception(errorMsg);
  }

  // ─── HTTP Methods ─────────────────────────────────────

  static Future<dynamic> get(String endpoint, {Map<String, String>? headers, Map<String, dynamic>? params}) async {
    var uri = Uri.parse('$baseUrl$endpoint');
    if (params != null && params.isNotEmpty) {
      uri = uri.replace(queryParameters: params.map((k, v) => MapEntry(k, v.toString())));
    }
    final response = await http.get(uri, headers: _buildHeaders(headers)).timeout(_timeout);
    return _processResponse(response);
  }

  static Future<dynamic> post(String endpoint, {dynamic body, Map<String, String>? headers, Map<String, dynamic>? params}) async {
    var uri = Uri.parse('$baseUrl$endpoint');
    if (params != null && params.isNotEmpty) {
      uri = uri.replace(queryParameters: params.map((k, v) => MapEntry(k, v.toString())));
    }
    final response = await http.post(
      uri,
      headers: _buildHeaders(headers),
      body: body != null ? jsonEncode(body) : null,
    ).timeout(_timeout);
    return _processResponse(response);
  }

  static Future<dynamic> put(String endpoint, {dynamic body, Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http.put(
      uri,
      headers: _buildHeaders(headers),
      body: body != null ? jsonEncode(body) : null,
    ).timeout(_timeout);
    return _processResponse(response);
  }

  static Future<dynamic> patch(String endpoint, {dynamic body, Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http.patch(
      uri,
      headers: _buildHeaders(headers),
      body: body != null ? jsonEncode(body) : null,
    ).timeout(_timeout);
    return _processResponse(response);
  }

  static Future<dynamic> delete(String endpoint, {Map<String, String>? headers}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http.delete(uri, headers: _buildHeaders(headers)).timeout(_timeout);
    return _processResponse(response);
  }
}
