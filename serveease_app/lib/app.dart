import 'package:flutter/material.dart';
import 'package:serveease_app/features/screens/providers/create_profile_screen.dart';
import 'package:serveease_app/features/screens/providers/profile_view_screen.dart';

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
        '/login': (context) =>  LoginScreen(),
         '/register': (context) => RegisterScreen(),
         '/provider/create-profile': (context) => CreateProfileScreen(),
          '/provider/profile': (context) => ProviderProfileViewScreen(),
          '/provider/edit-profile': (context) => CreateProfileScreen(isEditMode: true),
        '/forgot-password': (context) =>  ForgotPasswordScreen(),
        '/reset-password': (context) =>  ResetPasswordScreen(),
        '/verify-email': (context) => VerifyEmailScreen(),
        '/home': (context) => const HomeScreen(),
        // '/provider-setup': (context) => const ProviderSetupScreen(),
      },
    );
  }
}
