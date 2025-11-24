// ignore_for_file: unused_element_parameter, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthGuard {
  static final AuthService _auth = AuthService();

  /// Check if user has a stored token
  static Future<bool> isLoggedIn() async {
    final token = await _auth.getAccessToken();
    return token != null && token.isNotEmpty;
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
