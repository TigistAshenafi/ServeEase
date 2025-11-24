import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

String _resolveBaseUrl() {
  if (kIsWeb)  return 'http://localhost:3000/api/auth';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://localhost:3000/api/auth';
  } 
    return 'http://localhost:3000/api/auth';
}
class ApiService {
  // final String baseUrl = 'http://localhost:3000/api/auth'; // or your server IP
  final String baseUrl = _resolveBaseUrl();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // return data to app
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }
}
