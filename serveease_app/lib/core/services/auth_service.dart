// ignore_for_file: unused_field

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_service.dart';

String _resolveBaseUrl() {
  if (kIsWeb)  return 'http://localhost:3000/api/auth';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://localhost:3000/api/auth';
  } 
    return 'http://localhost:3000/api/auth';
}
class AuthService {
  final ApiService _api = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _resolveBaseUrl(),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // register
  Future<Response> register(String email, String password, String role, {String? name}) async {
    return await _dio.post('/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    });
  }

  // verify email
  Future<Response> verifyEmail(String email, String code) async {
    return await _dio.post('/verify-email', data: { 'email': email, 'code': code });
  }

  // login - returns accessToken in body
  Future<Response> login(String email, String password) async {
    return await _dio.post('/login', data: { 'email': email, 'password': password });
  }

  // request password reset
  Future<Response> requestPasswordReset(String email) async {
    return await _dio.post('/request-password-reset', data: { 'email': email });
  }

  // reset password
  Future<Response> resetPassword(String token, String newPassword, String email) async {
    return await _dio.post('/reset-password', data: { 'token': token, 'newPassword': newPassword, 'email': email });
  }

  // Save access token
  Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(key: 'ACCESS_TOKEN', value: token);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'ACCESS_TOKEN');
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: 'ACCESS_TOKEN');
    // optional: call backend /logout to clear cookie
    try { await _dio.post('/logout'); } catch (_) {}
  }
}
