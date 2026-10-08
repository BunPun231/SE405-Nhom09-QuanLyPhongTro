import '../network/api_client.dart';

// ─── Models (mirror authService.ts) ─────────────────────────────────────────

class AuthResponse {
  final String accessToken;
  final String? refreshToken;
  final String userId;
  final String? tenantId;
  final String role;
  final String fullName;
  final bool hasCompletedOnboarding;

  AuthResponse({
    required this.accessToken,
    this.refreshToken,
    required this.userId,
    this.tenantId,
    required this.role,
    required this.fullName,
    required this.hasCompletedOnboarding,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'],
      userId: json['userId'] ?? '',
      tenantId: json['tenantId'],
      role: json['role'] ?? '',
      fullName: json['fullName'] ?? '',
      hasCompletedOnboarding: json['hasCompletedOnboarding'] ?? false,
    );
  }
}

class OnboardingStatusResult {
  final bool hasCompletedOnboarding;
  final bool hasMotel;
  final bool hasSePayConfig;
  final bool hasRooms;
  final bool hasActiveContract;
  final bool hasMeterReadings;
  final bool hasInvoice;
  final int currentStep;

  OnboardingStatusResult({
    required this.hasCompletedOnboarding,
    required this.hasMotel,
    required this.hasSePayConfig,
    required this.hasRooms,
    required this.hasActiveContract,
    required this.hasMeterReadings,
    required this.hasInvoice,
    required this.currentStep,
  });

  factory OnboardingStatusResult.fromJson(Map<String, dynamic> json) {
    return OnboardingStatusResult(
      hasCompletedOnboarding: json['hasCompletedOnboarding'] ?? false,
      hasMotel: json['hasMotel'] ?? false,
      hasSePayConfig: json['hasSePayConfig'] ?? false,
      hasRooms: json['hasRooms'] ?? false,
      hasActiveContract: json['hasActiveContract'] ?? false,
      hasMeterReadings: json['hasMeterReadings'] ?? false,
      hasInvoice: json['hasInvoice'] ?? false,
      currentStep: json['currentStep'] ?? 0,
    );
  }
}

// ─── AuthService (mirror authService.ts) ─────────────────────────────────────

class AuthService {
  /// UC02: Login — POST /api/public/auth/login
  static Future<AuthResponse> login(String identity, String password) async {
    // Backend trả về { data: AuthResponse } — ApiClient tự extract 'data'
    final data = await ApiClient.post('/api/public/auth/login', body: {
      'identity': identity,
      'password': password,
    });
    final authRes = AuthResponse.fromJson(data as Map<String, dynamic>);
    // Lưu session (giống authStore.login)
    await ApiClient.setSession(
      accessToken: authRes.accessToken,
      tenantId: authRes.tenantId,
      userId: authRes.userId,
    );
    return authRes;
  }

  /// UC01: Register — POST /api/public/auth/register
  static Future<void> register({
    required String tenantName,
    required String phone,
    String? email,
    required String fullName,
    required String password,
  }) async {
    await ApiClient.post('/api/public/auth/register', body: {
      'tenantName': tenantName,
      'phone': phone,
      if (email != null) 'email': email,
      'fullName': fullName,
      'password': password,
    });
  }

  /// UC05: Change password — POST /api/v1/auth/change-password
  static Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await ApiClient.post('/api/v1/auth/change-password', body: {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
  }

  /// UC06: Forgot password — POST /api/v1/auth/forgot-password
  static Future<void> forgotPassword(String identity) async {
    await ApiClient.post('/api/v1/auth/forgot-password', body: {'identity': identity});
  }

  /// UC06: Reset password with OTP — POST /api/v1/auth/reset-password
  static Future<void> resetPassword({
    required String identity,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await ApiClient.post('/api/v1/auth/reset-password', body: {
      'identity': identity,
      'otp': otp,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
  }

  /// Refresh token — POST /api/public/auth/refresh
  static Future<AuthResponse> refresh(String refreshToken) async {
    final data = await ApiClient.post('/api/public/auth/refresh', body: {'refreshToken': refreshToken});
    final authRes = AuthResponse.fromJson(data as Map<String, dynamic>);
    await ApiClient.setSession(
      accessToken: authRes.accessToken,
      tenantId: authRes.tenantId,
      userId: authRes.userId,
    );
    return authRes;
  }

  /// Get onboarding status — GET /api/v1/users/onboarding-status
  static Future<OnboardingStatusResult> getOnboardingStatus() async {
    final data = await ApiClient.get('/api/v1/users/onboarding-status');
    return OnboardingStatusResult.fromJson(data as Map<String, dynamic>);
  }

  /// Mark onboarding complete — PUT /api/v1/users/onboarding-complete
  static Future<void> completeOnboarding() async {
    await ApiClient.put('/api/v1/users/onboarding-complete');
  }

  /// Logout (giống authStore.logout — clear session, redirect to login)
  static Future<void> logout() async {
    await ApiClient.logout();
  }
}
