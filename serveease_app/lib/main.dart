import 'package:flutter/material.dart';
// import 'app.dart';
import 'core/guards/auth_guard.dart';
import 'features/auth/presentation/home_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/signup_screen.dart';
import 'features/auth/presentation/email_verification_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ServeEaseApp());
}

class ServeEaseApp extends StatelessWidget {
  const ServeEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ServeEase',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
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
        // Handle dynamic routes with arguments
        if (settings.name == '/verify-email') {
          // No need to pass email in constructor
          return MaterialPageRoute(
            builder: (context) => const EmailVerificationScreen(),
            settings: settings, // keep settings so ModalRoute can access arguments
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
}
