// lib/core/services/auth_service.dart
import 'dart:convert';
import 'package:serveease_app/core/models/user_model.dart';
import 'api_service.dart';

class AuthService {
  /// Register new user
  static Future<ApiResponse<User>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final res = await ApiService.post(
        '${ApiService.authBase}/register',
        withAuth: false,
        body: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        },
      );
      return ApiService.handleResponse<User>(
        res,
        (json) => User.fromJson(json['user'] ?? json),
      );
    } catch (e) {
      return ApiService.handleError<User>(e);
    }
  }

  /// Verify email using code
  static Future<ApiResponse<User>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final res = await ApiService.get(
        '${ApiService.authBase}/verify-email',
        withAuth: false,
        params: {'email': email, 'code': code},
      );
      return ApiService.handleResponse<User>(
        res,
        (json) => User.fromJson(json['user'] ?? json),
      );
    } catch (e) {
      return ApiService.handleError<User>(e);
    }
  }

  // Add to your AuthService class
/// Resend verification code
static Future<ApiResponse<void>> resendVerificationCode({
  required String email,
}) async {
  try {
    final res = await ApiService.post(
      '${ApiService.authBase}/resend-verification-code',
      withAuth: false,
      body: {'email': email},
    );
    
    // Use the same pattern as verifyEmail
    return ApiService.handleResponse<void>(
      res,
      (json) {}, // No data to parse for void response
    );
  } catch (e) {
    return ApiService.handleError<void>(e);
  }
}
 
  /// Login, persist access token and refresh cookie
  static Future<ApiResponse<LoginResponse>> login({
    required String email,
    required String password,
    String? loginAs,
  }) async {
    try {
      final res = await ApiService.post(
        '${ApiService.authBase}/login',
        withAuth: false,
        body: {
          'email': email,
          'password': password,
          if (loginAs != null) 'loginAs': loginAs,
        },
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final json = jsonDecode(res.body);
        final token = json['accessToken'] as String?;
        if (token != null) {
          await ApiService.setAccessToken(token);
        }
        final user = User.fromJson(json['user']);
        return ApiResponse<LoginResponse>(
          success: true,
          message: json['message'] ?? 'Login successful',
          data: LoginResponse(user: user, accessToken: token ?? ''),
        );
      }

      final parsed = ApiService.handleResponse<dynamic>(res, null);
      return ApiResponse<LoginResponse>(
        success: false,
        message: parsed.message,
      );
    } catch (e) {
      return ApiService.handleError<LoginResponse>(e);
    }
  }

  /// Send password reset code
  static Future<ApiResponse<void>> forgotPassword(String email) async {
    try {
      final res = await ApiService.post(
        '${ApiService.authBase}/forgot-password',
        withAuth: false,
        body: {'email': email},
      );
      return ApiService.handleResponse<void>(res, null);
    } catch (e) {
      return ApiService.handleError<void>(e);
    }
  }

  /// Reset password with code
  static Future<ApiResponse<void>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final res = await ApiService.post(
        '${ApiService.authBase}/reset-password',
        withAuth: false,
        body: {
          'email': email,
          'code': code,
          'newPassword': newPassword,
        },
      );
      return ApiService.handleResponse<void>(res, null);
    } catch (e) {
      return ApiService.handleError<void>(e);
    }
  }

  /// Get current user profile
  static Future<ApiResponse<User>> getProfile() async {
    try {
      final res = await ApiService.get('${ApiService.authBase}/profile');
      return ApiService.handleResponse<User>(
        res,
        (json) => User.fromJson(json['user'] ?? json),
      );
    } catch (e) {
      return ApiService.handleError<User>(e);
    }
  }

  /// Logout and clear tokens
  static Future<ApiResponse<void>> logout() async {
    try {
      final res = await ApiService.post('${ApiService.authBase}/logout');
      await ApiService.clearTokens();
      return ApiService.handleResponse<void>(res, null);
    } catch (e) {
      await ApiService.clearTokens();
      return ApiService.handleError<void>(e);
    }
  }
}

class LoginResponse {
  final User user;
  final String accessToken;

  LoginResponse({
    required this.user,
    required this.accessToken,
  });
}