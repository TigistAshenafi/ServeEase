// lib/screens/register_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:serveease_app/providers/auth_provider.dart';
import 'package:serveease_app/shared/widgets/custom_button.dart';
import 'package:serveease_app/shared/widgets/custom_text_field.dart';
import 'package:serveease_app/core/utils/responsive.dart';
import 'package:serveease_app/shared/widgets/language_toggle.dart';
import 'package:serveease_app/shared/widgets/role_selector.dart';
import 'package:serveease_app/l10n/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  Role _role = Role.seeker;
  bool get _isProvider => _role == Role.provider;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final loc = AppLocalizations.of(context)!;

    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.validationPasswordsMismatch),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final response = await authProvider.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _isProvider ? 'provider' : 'seeker',
      );

      if (response.success) {
        if (!mounted) return;
        Navigator.pushNamed(
          context,
          "/verify-email",
          arguments: {
            "email": _emailController.text.trim(),
            "role": _isProvider ? 'provider' : 'seeker',
          },
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: ResponsiveWidget(
          mobile: _buildMobileLayout(context, authProvider, theme, colorScheme, loc),
          tablet: _buildTabletLayout(context, authProvider, theme, colorScheme, loc),
          desktop: _buildDesktopLayout(context, authProvider, theme, colorScheme, loc),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, AuthProvider authProvider, ThemeData theme, ColorScheme colorScheme, AppLocalizations loc) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LanguageToggle(alignment: Alignment.centerRight),
            SizedBox(height: 16.h),
            _buildHeader(context, theme, colorScheme, loc),
            SizedBox(height: 48.h),
            _buildSignupForm(context, authProvider, theme, colorScheme, loc),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, AuthProvider authProvider, ThemeData theme, ColorScheme colorScheme, AppLocalizations loc) {
    return Center(
      child: SizedBox(
        width: 500.w,
        child: _buildMobileLayout(context, authProvider, theme, colorScheme, loc),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, AuthProvider authProvider, ThemeData theme, ColorScheme colorScheme, AppLocalizations loc) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.85)],
              ),
            ),
            child: Center(
              child: Text(
                'ServeEase',
                style: theme.textTheme.displayLarge?.copyWith(color: Colors.white),
              ).animate().fadeIn(),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: SizedBox(
              width: 420.w,
              child: _buildMobileLayout(context, authProvider, theme, colorScheme, loc),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations loc,
  ) {
  return Center(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          loc.createAccountTitle,
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onBackground,
          ),
        ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
        SizedBox(height: 8.h),
        Text(
          loc.signupSubtitle,
          textAlign: TextAlign.center, // ensure subtitle is centered
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2),
      ],
    ),
  );
}

  Widget _buildSignupForm(BuildContext context, AuthProvider authProvider, ThemeData theme, ColorScheme colorScheme, AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NameTextField(
          controller: _nameController,
          label: loc.nameLabel,
          hint: loc.nameValidation,
          validator: (v) => (v == null || v.trim().isEmpty) ? loc.nameValidation : (v.length < 3 ? loc.validationNameLength : null),
        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
        SizedBox(height: 24.h),
        EmailTextField(
          controller: _emailController,
          label: loc.emailLabel,
          hint: loc.emailHint,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return loc.validationEmailRequired;
            return null;
          },
        ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2),
        SizedBox(height: 24.h),
        PasswordTextField(
          controller: _passwordController,
          label: loc.passwordLabel,
          hint: loc.passwordHint,
          // obscureText: _obscurePassword,
          // toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
          validator: (v) => (v == null || v.isEmpty)
              ? loc.validationPasswordRequired
              : (v.length < 6)
                  ? loc.validationPasswordLength
                  : null,
        ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),
        SizedBox(height: 24.h),
        ConfirmPasswordTextField(
          controller: _confirmPasswordController,
          label: loc.confirmPasswordLabel,
          hint: loc.confirmPasswordLabel,
          // obscureText: _obscureConfirmPassword,
          // toggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          validator: (v) => (v == null || v.isEmpty)
              ? loc.validationConfirmPassword
              : (v != _passwordController.text)
                  ? loc.validationPasswordsMismatch
                  : null,
        ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.2),
        SizedBox(height: 24.h),
        _buildRoleSelection(theme, colorScheme, loc).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.2),
        if (_isProvider)
          Padding(
            padding: EdgeInsets.only(top: 16.h),
            child: Text(
              loc.providerInfoNote,
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary),
            ),
          ),
        SizedBox(height: 32.h),
        PrimaryButton(
          text: loc.signupSubmitLabel,
          onPressed: _register,
          isLoading: authProvider.isLoading,
          isFullWidth: true,
        ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.2),
        SizedBox(height: 24.h),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                loc.loginRedirectPrefix,
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: Text(
                  loc.loginRedirectAction,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 1300.ms),
      ],
    );
  }

  Widget _buildRoleSelection(ThemeData theme, ColorScheme colorScheme, AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.joinAsLabel,
          style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _role = Role.seeker),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    color: _role == Role.seeker ? colorScheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: _role == Role.seeker
                        ? null
                        : Border.all(color: colorScheme.outline.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.person_search_rounded,
                          color: _role == Role.seeker ? Colors.white : colorScheme.onSurfaceVariant),
                      SizedBox(height: 8.h),
                      Text(
                        loc.serviceSeekerLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: _role == Role.seeker ? FontWeight.w600 : FontWeight.w500,
                          color: _role == Role.seeker ? Colors.white : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _role = Role.provider),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    color: _role == Role.provider ? colorScheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: _role == Role.provider
                        ? null
                        : Border.all(color: colorScheme.outline.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.work_rounded,
                          color: _role == Role.provider ? Colors.white : colorScheme.onSurfaceVariant),
                      SizedBox(height: 8.h),
                      Text(
                        loc.serviceProviderLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: _role == Role.provider ? FontWeight.w600 : FontWeight.w500,
                          color: _role == Role.provider ? Colors.white : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
