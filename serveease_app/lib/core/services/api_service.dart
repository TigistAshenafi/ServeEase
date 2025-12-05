// lib/services/api_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

String resolveBaseUrl() {
  if (kIsWeb) return "http://localhost:3000";

  if (defaultTargetPlatform == TargetPlatform.android) {
    return "http://10.0.2.2:3000"; // For Android emulator
  }

  return "http://localhost:3000"; // Windows, macOS, iOS
}

class ApiService {
  final String baseUrl = resolveBaseUrl();

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 201) return body;

    throw Exception(body['message'] ?? 'Registration failed');
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 200) return body;

    throw Exception(body['message'] ?? 'Failed to login');
  }
}
