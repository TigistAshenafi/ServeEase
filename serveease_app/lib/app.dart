import 'package:flutter/material.dart';
// import 'config/theme.dart';
import 'features/auth/presentation/welcome_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/signup_screen.dart';
import 'features/auth/presentation/forgot_password_screen.dart';
import 'features/auth/presentation/reset_password_screen.dart';
import 'features/auth/presentation/email_verification_screen.dart';
import 'features/auth/presentation/home_screen.dart';

class ServeEaseApp extends StatelessWidget {
  const ServeEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ServeEase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/verify-email': (context) => const EmailVerificationScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
