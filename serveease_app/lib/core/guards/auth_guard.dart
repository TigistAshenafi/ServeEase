// ignore_for_file: use_build_context_synchronously, unused_element_parameter

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AuthGuard {
  // We'll use the static methods directly from ApiService

  /// Check if user has a stored token
  static Future<bool> isLoggedIn() async {
    // Initialize ApiService if not already done
    await ApiService.init();
    
    // Check if we have an access token
    final response = await AuthService.getProfile();
    return response.success && response.data != null;
  }

  /// Alternative: Check token directly from storage
  static Future<bool> hasValidToken() async {
    await ApiService.init();
    
    // Try to get profile which will validate the token
    try {
      final response = await AuthService.getProfile();
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// Wrapper for protected screens
  static Future<Route> protect({
    required BuildContext context,
    required WidgetBuilder builder,
  }) async {
    final loggedIn = await isLoggedIn();

    if (!loggedIn) {
      return MaterialPageRoute(
        builder: (_) => const _RedirectToLogin(),
      );
    }

    return MaterialPageRoute(builder: builder);
  }

  /// Stream-based authentication check for real-time updates
  static Stream<bool> get authStateChanges async* {
    // Initial check
    yield await isLoggedIn();
    
    // You can add logic here to listen for auth state changes
    // For example, using a provider or stream controller
  }
}

class _RedirectToLogin extends StatelessWidget {
  const _RedirectToLogin({super.key});

  @override
  Widget build(BuildContext context) {
    Future.microtask(() =>
        Navigator.pushReplacementNamed(context, '/login'));
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}