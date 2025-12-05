import 'package:flutter/material.dart';
import 'package:serveease_app/features/auth/presentation/provider_setup_screen.dart';
import 'package:serveease_app/features/auth/presentation/welcome_screen.dart';
import 'package:serveease_app/l10n/app_localizations.dart';

import 'core/guards/auth_guard.dart';
import 'core/localization/locale_controller.dart';
import 'features/auth/presentation/home_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/signup_screen.dart';
import 'features/auth/presentation/forgot_password_screen.dart';
import 'features/auth/presentation/reset_password_screen.dart';
import 'features/auth/presentation/email_verification_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ServeEaseApp());
}

class ServeEaseApp extends StatelessWidget {
  const ServeEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localeController,
      builder: (context, _) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      locale: localeController.locale,
      supportedLocales: LocaleController.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      initialRoute: '/welcome',
      routes: {
        '/welcome': (_) => const WelcomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/provider-setup': (_) => const ProviderSetupScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/reset-password': (_) => const ResetPasswordScreen(),
        '/home': (context) => FutureBuilder<bool>(
              future: AuthGuard.isLoggedIn(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                return snapshot.data == true
                    ? const HomeScreen()
                    : const LoginScreen();
              },
            ),
      },
onGenerateRoute: (settings) {
  // Handle dynamic routes with arguments for reset-password and verify-email
  if (settings.name == '/reset-password') {
    return MaterialPageRoute(
      builder: (context) => const ResetPasswordScreen(),
      settings: settings,
    );
  }

  if (settings.name == '/verify-email') {
    return MaterialPageRoute(
      builder: (context) => const EmailVerificationScreen(),
      settings: settings,
    );
  }

  return null;
},

      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
      },
    );
      }
      );
  }
}
