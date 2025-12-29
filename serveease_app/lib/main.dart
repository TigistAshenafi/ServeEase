// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:serveease_app/core/localization/locale_controller.dart';

import 'package:serveease_app/core/services/api_service.dart';
import 'package:serveease_app/core/theme/app_theme.dart';
import 'package:serveease_app/l10n/app_localizations.dart';

// 🔥 Locale controller (YOUR EXISTING ONE)
// import 'package:serveease_app/core/controllers/locale_controller.dart';

import 'package:serveease_app/features/admin/provider_approvals_screen.dart';
import 'package:serveease_app/features/ai/ai_chat_screen.dart';
import 'package:serveease_app/features/auth/presentation/email_verification_screen.dart';
import 'package:serveease_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:serveease_app/features/auth/presentation/home_screen.dart';
import 'package:serveease_app/features/auth/presentation/login_screen.dart';
import 'package:serveease_app/features/auth/presentation/reset_password_screen.dart';
import 'package:serveease_app/features/auth/presentation/signup_screen.dart';
import 'package:serveease_app/features/employees/employee_list_screen.dart';
import 'package:serveease_app/features/requests/request_list_screen.dart';
import 'package:serveease_app/features/screens/providers/create_profile_screen.dart';
import 'package:serveease_app/features/screens/providers/profile_view_screen.dart';
import 'package:serveease_app/features/services/my_services_screen.dart';
import 'package:serveease_app/features/services/service_catalog_screen.dart';
import 'package:serveease_app/features/chat/screens/conversations_screen.dart';
import 'package:serveease_app/features/chat/screens/chat_screen.dart';

import 'package:serveease_app/providers/admin_provider.dart';
import 'package:serveease_app/providers/ai_provider.dart';
import 'package:serveease_app/providers/auth_provider.dart';
import 'package:serveease_app/providers/employee_provider.dart';
import 'package:serveease_app/providers/provider_profile_provider.dart';
import 'package:serveease_app/providers/service_provider.dart';
import 'package:serveease_app/providers/service_request_provider.dart';
import 'package:serveease_app/features/chat/providers/chat_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await ApiService.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ProviderProfileProvider()),
            ChangeNotifierProvider(create: (_) => ServiceProvider()),
            ChangeNotifierProvider(create: (_) => ServiceRequestProvider()),
            ChangeNotifierProvider(create: (_) => EmployeeProvider()),
            ChangeNotifierProvider(create: (_) => AiProvider()),
            ChangeNotifierProvider(create: (_) => AdminProvider()),
            ChangeNotifierProvider(create: (_) => ChatProvider()),
          ],
          child: AnimatedBuilder(
            animation: localeController,
            builder: (context, _) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,

                // 🌍 LOCALIZATION (CONNECTED TO CONTROLLER)

                locale: localeController.locale,
                supportedLocales: LocaleController.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],

                onGenerateTitle: (context) =>
                    AppLocalizations.of(context)?.appTitle ?? 'ServeEase',

                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: ThemeMode.system,

                home: const AuthWrapper(),

                routes: {
                  '/login': (_) => LoginScreen(),
                  '/register': (_) => const RegisterScreen(),
                  '/home': (_) => const HomeScreen(),
                  '/provider/create-profile': (_) =>
                      const CreateProfileScreen(),
                  '/provider/profile': (_) => const ProviderProfileViewScreen(),
                  '/provider/edit-profile': (_) =>
                      const CreateProfileScreen(isEditMode: true),
                  '/verify-email': (_) => const VerifyEmailScreen(),
                  '/forgot-password': (_) => ForgotPasswordScreen(),
                  '/reset-password': (_) => ResetPasswordScreen(),
                  '/services/catalog': (_) => const ServiceCatalogScreen(),
                  '/services/my': (_) => const MyServicesScreen(),
                  '/requests': (_) => const RequestListScreen(),
                  '/employees': (_) => const EmployeeListScreen(),
                  '/ai': (_) => const AiChatScreen(),
                  '/admin/providers': (_) => const ProviderApprovalsScreen(),
                  '/chat': (_) => const ConversationsScreen(),
                },
                onGenerateRoute: (settings) {
                  // Handle dynamic routes like /chat/:conversationId
                  if (settings.name?.startsWith('/chat/') == true) {
                    final conversationId = settings.name!.split('/')[2];
                    return MaterialPageRoute(
                      builder: (context) => ChatScreen(conversationId: conversationId),
                    );
                  }
                  return null;
                },
              );
            },
          ),
        );
      },
    );
  }
}

// -------------------- AUTH WRAPPER --------------------

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().initialize();
      
      // Initialize chat service when user is authenticated
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated) {
        _initializeChat();
      }
    });
  }

  void _initializeChat() async {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';
    await context.read<ChatProvider>().initialize(baseUrl);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (auth.isAuthenticated) {
      // Initialize chat when authenticated
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeChat();
      });
      return const HomeScreen();
    }

    return LoginScreen();
  }
}



// class AuthWrapper extends StatefulWidget {
//   @override
//   _AuthWrapperState createState() => _AuthWrapperState();
// }

// class _AuthWrapperState extends State<AuthWrapper> {
//   @override
//   void initState() {
//     super.initState();
//     _initializeAuth();
//   }

//   Future<void> _initializeAuth() async {
//     await Provider.of<AuthProvider>(context, listen: false).initialize();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = Provider.of<AuthProvider>(context);
    
//     if (authProvider.isLoading) {
//       // return SplashScreen();
//     }
    
//     if (authProvider.isAuthenticated) {
//       return HomeScreen();
//     }
    
//     return LoginScreen();
//   }
// }