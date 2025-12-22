import 'package:flutter/material.dart';
import 'package:serveease_app/core/models/user_model.dart';
import 'package:serveease_app/core/services/api_service.dart';
import 'package:serveease_app/core/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  // 🔥 IMPORTANT FIX
  bool isInitialized = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  // Initialize auth state
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await AuthService.getProfile();

      if (response.success && response.data != null) {
        _user = response.data;
        _isAuthenticated = true;
      } else {
        await AuthService.logout();
        _isAuthenticated = false;
      }
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
    } finally {
      _isLoading = false;

      // 🔥 Set this AFTER finishing initialization
      isInitialized = true;

      notifyListeners();
    }
  }

  // Register
  Future<ApiResponse<User>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await AuthService.register(
      name: name,
      email: email,
      password: password,
      role: role,
    );

    _isLoading = false;

    if (response.success) {
      _user = response.data;
      notifyListeners();
    } else {
      _error = response.message;
      notifyListeners();
    }

    return response;
  }

  // Verify email
  Future<ApiResponse<User>> verifyEmail({
    required String email,
    required String code,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await AuthService.verifyEmail(email: email, code: code);

    _isLoading = false;

    if (response.success && response.data != null) {
      _user = response.data;
      notifyListeners();
    } else {
      _error = response.message;
      notifyListeners();
    }

    return response;
  }

// Add this method to your AuthProvider class
Future<ApiResponse<void>> resendVerificationCode(String email) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  final response = await AuthService.resendVerificationCode(email: email);

  _isLoading = false;
  
  if (!response.success) {
    _error = response.message;
  }
  
  notifyListeners();
  return response;
}

  // Login
  Future<ApiResponse<LoginResponse>> login({
    required String email,
    required String password,
    String? loginAs,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await AuthService.login(
        email: email,
        password: password,
        loginAs: loginAs,
       
      );

      _isLoading = false;

      if (response.success && response.data != null) {
        _user = response.data!.user;
        _isAuthenticated = true;
        notifyListeners();
      } else {
        _error = response.message;
        notifyListeners();
      }

      return response;
    } catch (e) {
      _isLoading = false;
      _error = 'Login failed: ${e.toString()}';
      notifyListeners();
      
      return ApiResponse<LoginResponse>(
        success: false,
        message: 'Login failed: ${e.toString()}',
      );
    }
  }

  // Forgot password
  Future<ApiResponse<void>> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await AuthService.forgotPassword(email);

    _isLoading = false;

    if (!response.success) {
      _error = response.message;
      notifyListeners();
    }

    return response;
  }

  // Reset password
  Future<ApiResponse<void>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await AuthService.resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );

    _isLoading = false;

    if (!response.success) {
      _error = response.message;
      notifyListeners();
    }

    return response;
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await AuthService.logout();

    _user = null;
    _isAuthenticated = false;
    _isLoading = false;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Manually set user
  void setUser(User user) {
    _user = user;
    _isAuthenticated = true;
    notifyListeners();
  }
}
