// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:serveease_app/core/models/user_model.dart';
import 'package:serveease_app/core/utils/validators.dart';
import 'package:serveease_app/providers/auth_provider.dart';
import 'package:serveease_app/shared/widgets/custom_button.dart';
// import 'package:serveease_app/shared/widgets/custom_text_field.dart';
import 'package:serveease_app/core/utils/responsive.dart';
import 'package:serveease_app/l10n/app_localizations.dart';
import 'package:serveease_app/shared/widgets/language_toggle.dart'; // <-- added

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _loginAs;
  bool _obscurePassword = true;
  bool _showRoleSelection = false;

  String? _redirectTo;
  String? _prefilledEmail;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _prefilledEmail = args['email'];
        _redirectTo = args['redirectTo'];
        _successMessage = args['message'];

        if (_prefilledEmail != null) {
          _emailController.text = _prefilledEmail!;
          _checkUserType();
        }

        if (_successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_successMessage!),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _checkUserType() {
    if (_emailController.text.trim().isNotEmpty) {
      setState(() => _showRoleSelection = true);
    }
  }

//  Future<void> _login() async {
//   if (!_formKey.currentState!.validate()) return;

//   final authProvider = Provider.of<AuthProvider>(context, listen: false);

//   if (_showRoleSelection && _loginAs == null) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(AppLocalizations.of(context)?.selectRoleError ?? 'Please select your role'),
//         backgroundColor: Colors.red,
//       ),
//     );
//     return;
//   }

//   final response = await authProvider.login(
//     email: _emailController.text.trim(),
//     password: _passwordController.text,
//     loginAs: _loginAs,
//   );

//   if (!mounted) return;

//   if (response.success) {
//     // SAFE ACCESS: Handle role access properly
//     dynamic userRole;
    
//     // Try multiple ways to get role
//     if (response.data is User) {
//       userRole = (response.data as User).role;
//     } else if (response.data is Map) {
//       final data = response.data as Map;
//       userRole = data['role'] ?? data['user']?['role'];
//     }
    
//     // Fallback: Use loginAs selection if role not in response
//     final effectiveRole = userRole?.toString() ?? _loginAs;
    
//     String targetRoute;
    
//     if (effectiveRole == 'provider') {
//       // Provider: Use redirect or default to create-profile
//       targetRoute = _redirectTo ?? '/provider/create-profile';
//     } else {
//       // Non-provider or seeker
//       targetRoute = _redirectTo ?? '/home';
//     }
    
//     // Debug output
//     print('Login Navigation:');
//     print('  Effective role: $effectiveRole');
//     print('  Redirect from args: $_redirectTo');
//     print('  Final route: $targetRoute');
    
//     Navigator.pushNamedAndRemoveUntil(
//       context,
//       targetRoute,
//       (_) => false,
//     );
//   } else {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(response.message),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }
// }


  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_showRoleSelection && _loginAs == null) {
      ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(AppLocalizations.of(context)?.selectRoleError ?? 'Please select your role'),
    backgroundColor: Colors.red,
  ),
);

      return;
    }

    final response = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      loginAs: _loginAs,
    );

    if (!mounted) return;

    if (response.success) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        _redirectTo ?? '/home',
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: ResponsiveWidget(
          mobile: _buildMobileLayout(
              context, authProvider, theme, colorScheme, l10n),
          tablet: _buildTabletLayout(
              context, authProvider, theme, colorScheme, l10n),
          desktop: _buildDesktopLayout(
              context, authProvider, theme, colorScheme, l10n),
        ),
      ),
    );
  }

  // -------------------- LAYOUTS --------------------

  Widget _buildMobileLayout(BuildContext context, AuthProvider auth,
      ThemeData theme, ColorScheme colors, AppLocalizations? l10n) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language toggle
            const LanguageToggle(alignment: Alignment.centerRight),
            const SizedBox(height: 16),

            _buildHeader(theme, colors, l10n),
            SizedBox(height: 48.h),
            _buildLoginForm(auth, theme, colors, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, AuthProvider auth,
      ThemeData theme, ColorScheme colors, AppLocalizations? l10n) {
    return Center(
      child: SizedBox(
        width: 500.w,
        child: _buildMobileLayout(context, auth, theme, colors, l10n),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, AuthProvider auth,
      ThemeData theme, ColorScheme colors, AppLocalizations? l10n) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.primary.withOpacity(0.85)],
              ),
            ),
            child: Center(
              child: Text(
                'ServeEase',
                style:
                    theme.textTheme.displayLarge?.copyWith(color: Colors.white),
              ).animate().fadeIn(),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: SizedBox(
              width: 420.w,
              child: _buildMobileLayout(context, auth, theme, colors, l10n),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------- HEADER --------------------

  Widget _buildHeader(
      ThemeData theme, ColorScheme colors, AppLocalizations? l10n) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            l10n?.loginWelcomeTitle ?? 'Welcome Back',
            style: theme.textTheme.displayMedium
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center, // ensures the title is centered
          ).animate().fadeIn(),
          SizedBox(height: 8.h),
          Text(
            l10n?.loginSubtitle ?? 'Login to continue',
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center, // ensures subtitle is centered
          ),
        ],
      ),
    );
  }

  // -------------------- FORM --------------------

  Widget _buildLoginForm(
    AuthProvider auth,
    ThemeData theme,
    ColorScheme colors,
    AppLocalizations? l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Email field ---
        TextFormField(
          controller: _emailController,
          autovalidateMode: AutovalidateMode.disabled,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: l10n?.emailLabel ?? 'Email',
            hintText: l10n?.emailHint ?? 'Enter your email',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.email_outlined),
          ),
          validator: (value) => Validators.validateEmail(context, value),
          onChanged: (_) => _checkUserType(),
        ),
        SizedBox(height: 24.h),

        // --- Password field ---
        TextFormField(
          controller: _passwordController,
          autovalidateMode: AutovalidateMode.disabled,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: l10n?.passwordLabel ?? 'Password',
            hintText: l10n?.passwordHint ?? 'Enter your password',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (value) => Validators.validatePassword(context, value),
        ),
        SizedBox(height: 24.h),

        // --- Role selection ---
        if (_showRoleSelection) _buildRoleSelection(theme, colors, l10n),

        SizedBox(height: 32.h),

        // --- Login button ---
        PrimaryButton(
          text: l10n?.loginButtonLabel ?? 'Login',
          isLoading: auth.isLoading,
          isFullWidth: true,
          onPressed: _login,
        ),

        SizedBox(height: 24.h),

        // --- Forgot password ---

        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/forgot-password'),
            child: Text(
              l10n!.forgotPasswordLabel,
              style: const TextStyle(
                  color: Colors.blue, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // TextButton(
        //   onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
        //   child: Text(l10n?.forgotPasswordLabel ?? 'Forgot password?'),
        // ),

        // SizedBox(height: 24.h),

        // --- Signup redirect ---
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.signupRedirectPrefix ?? 'No account?'),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: Text(
                l10n.signupRedirectAction ?? 'Sign up',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Widget _buildLoginForm(AuthProvider auth, ThemeData theme, ColorScheme colors, AppLocalizations? l10n) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       EmailTextField(
  //         controller: _emailController,
  //         hintText: l10n?.emailHint,
  //         labelText: l10n?.emailLabel,
  //         onChanged: (_) => _checkUserType(),
  //       ),
  //       SizedBox(height: 24.h),
  //       PasswordTextField(
  //         controller: _passwordController,
  //         hintText: l10n.passwordHint,
  //         labelText: l10n.passwordLabel,
  //       ),
  //       SizedBox(height: 24.h),

  //       if (_showRoleSelection) _buildRoleSelection(theme, colors, l10n),

  //       SizedBox(height: 32.h),

  //       PrimaryButton(
  //         text: l10n?.loginButtonLabel ?? 'Login',
  //         isLoading: auth.isLoading,
  //         isFullWidth: true,
  //         onPressed: _login,
  //       ),

  //       SizedBox(height: 24.h),

  //       TextButton(
  //         onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
  //         child: Text(l10n?.forgotPasswordLabel ?? 'Forgot password?'),
  //       ),

  //       SizedBox(height: 24.h),

  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Text(l10n?.signupRedirectPrefix ?? 'No account?'),
  //           TextButton(
  //             onPressed: () => Navigator.pushNamed(context, '/register'),
  //             child: Text(
  //               l10n?.signupRedirectAction ?? 'Sign up',
  //               style: const TextStyle(fontWeight: FontWeight.w600),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  // -------------------- ROLE SELECTION --------------------

  Widget _buildRoleSelection(
      ThemeData theme, ColorScheme colors, AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.loginAsRole ?? 'Login As',
          style: theme.textTheme.labelLarge,
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _roleButton('seeker',
                  l10n?.serviceSeekerLabel ?? 'Service Seeker', Icons.person),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _roleButton('provider',
                  l10n?.serviceProviderLabel ?? 'Service Provider', Icons.work),
            ),
          ],
        ),
      ],
    );
  }

  Widget _roleButton(String role, String label, IconData icon) {
    final selected = _loginAs == role;

    return GestureDetector(
      onTap: () => setState(() => _loginAs = role),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: selected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? Colors.white : Colors.grey),
            SizedBox(height: 8.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
