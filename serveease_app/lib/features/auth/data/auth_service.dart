import 'dart:convert';
import 'package:dio/dio.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api/auth'));

  Future<Response> register(String name, String email, String password, String role) async {
    return await _dio.post('/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    });
  }

  Future<Response> login(String email, String password) async {
    return await _dio.post('/login', data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> verifyEmail(String email, String code) async {
    return await _dio.post('/verify-email', data: {
      'email': email,
      'code': code,
    });
  }

  Future<Response> requestPasswordReset(String email) async {
    return await _dio.post('/request-password-reset', data: {'email': email});
  }

  Future<Response> resetPassword(String email, String token, String newPassword) async {
    return await _dio.post('/reset-password', data: {
      'email': email,
      'token': token,
      'newPassword': newPassword,
    });
  }
}
