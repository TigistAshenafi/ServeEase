// lib/core/services/api_service.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Generic API response wrapper used across the app.
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });
}

/// Centralized HTTP client with token + cookie handling and automatic refresh.
class ApiService {
  ApiService._internal();
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  static final http.Client _client = http.Client();

  // Base URLs
  static String get _baseHost {
    try {
      return dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
    } catch (e) {
      // Fallback if dotenv is not initialized
      print('Warning: dotenv not initialized, using fallback URL');
      return 'http://localhost:3000';
    }
  }
  static String get authBase => '$_baseHost/api/auth';
  static String get providerBase => '$_baseHost/api/provider';
  static String get servicesBase => '$_baseHost/api/services';
  static String get serviceRequestBase => '$_baseHost/api/service-requests';
  static String get employeeBase => '$_baseHost/api/employees';
  static String get aiBase => '$_baseHost/api/ai';

  static String? _accessToken;
  static String? _refreshTokenCookie; // raw cookie string: refreshToken=xyz; Path=/

  /// Load stored tokens/cookies
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshTokenCookie = prefs.getString('refresh_cookie');
  }

  /// Persist access token
  static Future<void> setAccessToken(String token) async {
    _accessToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  /// Persist refresh cookie (as received from Set-Cookie)
  static Future<void> setRefreshCookie(String cookie) async {
    _refreshTokenCookie = cookie;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('refresh_cookie', cookie);
  }

  /// Remove all tokens
  static Future<void> clearTokens() async {
    _accessToken = null;
    _refreshTokenCookie = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_cookie');
  }



  /// Common headers
  static Map<String, String> _headers({bool withAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    if (_refreshTokenCookie != null) {
      headers['Cookie'] = _refreshTokenCookie!;
    }
    return headers;
  }

  /// Parse Set-Cookie header to persist refresh token cookie.
  static Future<void> _captureRefreshCookie(http.Response res) async {
    final setCookie = res.headers['set-cookie'];
    if (setCookie != null && setCookie.contains('refreshToken=')) {
      final refreshCookie =
          setCookie.split(',').firstWhere((c) => c.contains('refreshToken='));
      await setRefreshCookie(refreshCookie.split(';').first);
    }
  }

  /// Unified request handler with optional auto-refresh.
  static Future<http.Response> _send(
    Future<http.Response> Function(Map<String, String>) action, {
    bool withAuth = true,
    bool allowRefresh = true,
  }) async {
    final res = await action(_headers(withAuth: withAuth));

    // Capture refresh cookie on auth endpoints
    if (res.headers['set-cookie'] != null) {
      await _captureRefreshCookie(res);
    }

    // Attempt refresh on 401 once
    if (allowRefresh && res.statusCode == 401 && withAuth) {
      final refreshed = await refreshAccessToken();
      if (refreshed.success) {
        final retry = await action(_headers(withAuth: withAuth));
        return retry;
      }
    }

    return res;
  }

  /// GET helper
  static Future<http.Response> get(String url,
      {bool withAuth = true, Map<String, String>? params}) async {
    final uri = Uri.parse(url).replace(queryParameters: params);
    return _send((headers) => _client.get(uri, headers: headers),
        withAuth: withAuth);
  }

  /// POST helper
  static Future<http.Response> post(String url,
      {bool withAuth = true, Object? body}) {
    return _send(
      (headers) => _client.post(Uri.parse(url),
          headers: headers, body: body != null ? jsonEncode(body) : null),
      withAuth: withAuth,
    );
  }

  /// PUT helper
  static Future<http.Response> put(String url,
      {bool withAuth = true, Object? body}) {
    return _send(
      (headers) => _client.put(Uri.parse(url),
          headers: headers, body: body != null ? jsonEncode(body) : null),
      withAuth: withAuth,
    );
  }

  /// DELETE helper
  static Future<http.Response> delete(String url,
      {bool withAuth = true, Object? body}) {
    return _send(
      (headers) => _client.delete(Uri.parse(url),
          headers: headers, body: body != null ? jsonEncode(body) : null),
      withAuth: withAuth,
    );
  }

  /// Decode and map backend responses
  static ApiResponse<T> handleResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJson,
  ) {
    try {
      final json = jsonDecode(response.body);
      final ok = response.statusCode >= 200 && response.statusCode < 300;
      final success = ok && (json['success'] ?? true);

      if (success) {
        T? data;
        if (fromJson != null) {
          final payload = json['data'] ?? json['user'] ?? json['profile'] ?? json;
          data = fromJson(payload);
        }
        return ApiResponse<T>(
          success: true,
          message: json['message'] ?? 'Success',
          data: data,
        );
      }

      return ApiResponse<T>(
        success: false,
        message: json['message'] ?? 'Request failed',
      );
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        message: 'Failed to parse response',
      );
    }
  }

  /// Network error wrapper
  static ApiResponse<T> handleError<T>(Object e) {
    return ApiResponse<T>(
      success: false,
      message: e.toString(),
    );
  }

  /// Refresh access token using stored refresh cookie.
  static Future<ApiResponse<String>> refreshAccessToken() async {
    if (_refreshTokenCookie == null) {
      return ApiResponse(success: false, message: 'No refresh token');
    }
    try {
      final res = await _client.post(
        Uri.parse('$authBase/refresh-token'),
        headers: _headers(withAuth: false),
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final token = json['accessToken'] as String?;
        if (token != null) {
          await setAccessToken(token);
          return ApiResponse(success: true, message: 'refreshed', data: token);
        }
      }
      return ApiResponse(success: false, message: 'Refresh failed');
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }
}