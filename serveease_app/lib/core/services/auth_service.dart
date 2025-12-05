// ignore_for_file: unused_field

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';
import 'package:flutter/foundation.dart';

String _resolveBaseUrl() {
  // Base URL for API
  if (kIsWeb) return 'http://localhost:3000/api/auth';
  if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000/api/auth'; // Android emulator
  return 'http://localhost:3000/api/auth'; // iOS or desktop
}

class AuthService {
  final ApiService _api = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _resolveBaseUrl(),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // ------------------- REGISTER -------------------
  Future<Response> register(
    String email,
    String password,
    String role, {
    String? name,
    Map<String, dynamic>? providerProfile,
  }) async {
    final Map<String, dynamic> data = {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    };
    if (providerProfile != null) {
      data['providerProfile'] = providerProfile;
    }
    return await _dio.post('/register', data: data);
  }

  // ------------------- VERIFY EMAIL -------------------
  Future<Response> verifyEmail(String email, String code) async {
    return await _dio.post('/verify-email', data: {'email': email, 'code': code});
  }

  // ------------------- LOGIN -------------------
  Future<Response> login(String email, String password) async {
    final response = await _dio.post('/login', data: {'email': email, 'password': password});
    
    // Save access token if login successful
    if (response.statusCode == 200 && response.data['accessToken'] != null) {
      await saveAccessToken(response.data['accessToken']);
    }
    
    return response;
  }

  // ------------------- PASSWORD RESET -------------------
  Future<Response> requestPasswordReset(String email) async {
    return await _dio.post('/request-password-reset', data: {'email': email});
  }

  Future<Response> resetPassword(String token, String newPassword, String email) async {
    return await _dio.post('/reset-password', data: {
      'code': token,
      'email': email,
      'newPassword': newPassword,
    });
  }

  // ------------------- TOKEN MANAGEMENT -------------------
  Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(key: 'ACCESS_TOKEN', value: token);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'ACCESS_TOKEN');
  }

  /// Alias for backward compatibility
  Future<String?> getToken() async => getAccessToken();

  // ------------------- LOGOUT -------------------
  Future<void> logout() async {
    await _secureStorage.delete(key: 'ACCESS_TOKEN');
    try {
      await _dio.post('/logout');
    } catch (_) {}
  }

  // ------------------- DIO INSTANCE WITH AUTH -------------------
  /// Returns a Dio instance with Authorization header
  Future<Dio> dioWithAuth() async {
    final token = await getAccessToken();
    final dio = Dio(BaseOptions(
      baseUrl: _resolveBaseUrl(),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ));
    return dio;
  }
}
