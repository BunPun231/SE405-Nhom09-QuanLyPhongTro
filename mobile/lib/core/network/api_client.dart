import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

class ApiClient {
  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl.replaceFirst(RegExp(r'/$'), '');
    }
    if (kIsWeb) return 'http://localhost:8080';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }

  static const String _tenantHeader = 'X-Tenant-Id';
  static const Duration _timeout = Duration(seconds: 30);

  static String? _accessToken;
  static String? _tenantId;
  static String? _userId;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _tenantId = prefs.getString('tenant_id');
    _userId = prefs.getString('user_id');
    _userId ??= _userIdFromToken(_accessToken);
  }

  static Future<void> setSession({
    required String accessToken,
    String? tenantId,
    String? userId,
  }) async {
    _accessToken = accessToken;
    _tenantId = tenantId;
    _userId = userId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    if (tenantId != null) {
      await prefs.setString('tenant_id', tenantId);
    } else {
      await prefs.remove('tenant_id');
    }
    if (userId != null && userId.isNotEmpty) {
      await prefs.setString('user_id', userId);
    } else {
      await prefs.remove('user_id');
    }
  }

  static Future<void> logout() async {
    _accessToken = null;
    _tenantId = null;
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('tenant_id');
    await prefs.remove('user_id');
    await prefs.remove('user_role');
    await prefs.remove('user_fullname');
  }

  static String? get accessToken => _accessToken;
  static String? get tenantId => _tenantId;
  static String? get userId => _userId ?? _userIdFromToken(_accessToken);

  static String? _userIdFromToken(String? token) {
    if (token == null || token.isEmpty) return null;
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      final decoded = jsonDecode(utf8.decode(base64.decode(payload)));
      if (decoded is Map<String, dynamic>) {
        final sub = decoded['sub'] ?? decoded['userId'];
        if (sub != null && sub.toString().isNotEmpty) return sub.toString();
      }
    } catch (_) {}
    return null;
  }

  static Map<String, String> _buildHeaders([Map<String, String>? extra]) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${_accessToken!}';
    }
    if (_tenantId != null && _tenantId!.isNotEmpty) {
      headers[_tenantHeader] = _tenantId!;
    }
    if (extra != null) headers.addAll(extra);
    return headers;
  }

  static dynamic _processResponse(http.Response response) {
    final status = response.statusCode;

    if (status == 401) {
      logout();
      throw Exception('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
    }

    if (status >= 200 && status < 300) {
      if (response.body.isEmpty) return null;
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded;
    }

    String errorMsg = 'Lỗi kết nối máy chủ ($status)';
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        errorMsg = decoded['message'] ?? decoded['error'] ?? errorMsg;
      }
    } catch (_) {}
    throw Exception(errorMsg);
  }

  static Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? params,
  }) async {
    var uri = Uri.parse('$baseUrl$endpoint');
    if (params != null && params.isNotEmpty) {
      uri = uri.replace(
        queryParameters: params.map((k, v) => MapEntry(k, v.toString())),
      );
    }
    final response =
        await http.get(uri, headers: _buildHeaders(headers)).timeout(_timeout);
    return _processResponse(response);
  }

  static Future<dynamic> post(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    Map<String, dynamic>? params,
  }) async {
    var uri = Uri.parse('$baseUrl$endpoint');
    if (params != null && params.isNotEmpty) {
      uri = uri.replace(
        queryParameters: params.map((k, v) => MapEntry(k, v.toString())),
      );
    }
    final response = await http
        .post(
          uri,
          headers: _buildHeaders(headers),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_timeout);
    return _processResponse(response);
  }

  static Future<dynamic> put(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http
        .put(
          uri,
          headers: _buildHeaders(headers),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_timeout);
    return _processResponse(response);
  }

  static Future<dynamic> patch(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http
        .patch(
          uri,
          headers: _buildHeaders(headers),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_timeout);
    return _processResponse(response);
  }

  static Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http
        .delete(uri, headers: _buildHeaders(headers))
        .timeout(_timeout);
    return _processResponse(response);
  }

  /// POST multipart/form-data (upload ảnh). [files] gửi dưới field [fileField].
  static Future<dynamic> postMultipart(
    String endpoint, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
    // Content-Type (kèm boundary) do MultipartRequest tự đặt.
    request.headers.addAll(_buildHeaders()..remove('Content-Type'));
    if (fields != null) request.fields.addAll(fields);
    if (files != null) request.files.addAll(files);
    final streamed = await request.send().timeout(timeout);
    final response = await http.Response.fromStream(streamed);
    return _processResponse(response);
  }

  static Future<dynamic> registerFaceVector({
    required String userId,
    required String name,
    required List<double> embedding,
  }) async {
    final payload = {
      'userId': userId,
      'name': name,
      'embedding': embedding,
    };

    try {
      return await post('/api/faces/register', body: payload);
    } on Exception {
      return await post('/api/faces', body: payload);
    }
  }

  static Future<List<Map<String, dynamic>>> getFaceVectors() async {
    const endpoints = <String>[
      '/api/faces',
      '/api/faces/registered',
      '/api/faces/list',
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await get(endpoint);
        final list = response is List ? response : null;
        if (list != null) {
          return list
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        }

        if (response is Map<String, dynamic>) {
          final payload = response['items'] ?? response['data'];
          if (payload is List) {
            return payload
                .map((item) => Map<String, dynamic>.from(item as Map))
                .toList();
          }
        }
      } catch (_) {}
    }

    return const <Map<String, dynamic>>[];
  }
}
