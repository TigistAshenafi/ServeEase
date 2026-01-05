// lib/screens/forgot_password_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:serveease_app/core/utils/validators.dart';
import 'package:serveease_app/l10n/app_localizations.dart';
import 'package:serveease_app/providers/auth_provider.dart';
import 'package:serveease_app/shared/widgets/language_toggle.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isCodeSent = false;
  String? _sentEmail;
  bool _isResending = false; // for resend code loading

  Future<void> _sendResetCode() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final response = await authProvider.forgotPassword(email);

      if (!mounted) return;

      if (response.success) {
        setState(() {
          _isCodeSent = true;
          _sentEmail = email;
        });

        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.resetCodeSentMessage ?? 'Reset code sent to your email'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to reset password screen
        Navigator.pushReplacementNamed(
          context,
          '/reset-password',
          arguments: {'email': email},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n?.forgotPasswordTitle ?? 'Forgot Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language toggle
            const LanguageToggle(alignment: Alignment.centerRight),
            const SizedBox(height: 16),
            
            // Icon - Similar to Login
            Center(
              child: Icon(
                Icons.lock_reset,
                size: 80,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(height: 48.h),
            
            // Title - Similar styling to Login
            Center(
              child: Text(
                l10n?.forgotPasswordTitle ?? 'Forgot Password?',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 12.h),
            
            // Description text
            Text(
              _isCodeSent
                  ? 'We sent a 6-digit verification code to $_sentEmail\nPlease check your email and enter the code below.'
                  : l10n?.forgotPasswordSubtitle ?? 'Enter your email address and we\'ll send you a verification code to reset your password.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Email field - styled similar to Login
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: l10n?.emailLabel ?? 'Email Address',
                      hintText: l10n?.emailHint ?? 'Enter your email',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => Validators.validateEmail(context, value),
                  ),
                  SizedBox(height: 24.h),
                  
                  if (authProvider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    // Button - styled similar to Login's PrimaryButton
                    SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: ElevatedButton(
                        onPressed: _sendResetCode,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                          backgroundColor: colorScheme.primary,
                        ),
                        child: Text(
                          l10n?.sendResetLinkButton ?? 'Send Reset Code',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Back to Login - styled similar to Login's TextButton
            if (!_isCodeSent)
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n?.rememberPasswordPrefix ?? 'Remembered your password? '),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        l10n?.rememberPasswordAction ?? 'Sign In',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Resend Code / Try Another Email
            if (_isCodeSent)
              Column(
                children: [
                  SizedBox(height: 20.h),
                  const Divider(),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n?.didntReceiveCode ?? 'Didn\'t receive the code? ',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      _isResending
                          ? SizedBox(
                              width: 20.w,
                              height: 20.h,
                              child: const CircularProgressIndicator(strokeWidth: 2),
                            )
                          : TextButton(
                              onPressed: () async {
                                if (_sentEmail != null && _sentEmail!.isNotEmpty) {
                                  setState(() => _isResending = true);
                                  try {
                                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                    await authProvider.forgotPassword(_sentEmail!);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(l10n?.resetCodeSentMessage ?? 'Code resent successfully'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) setState(() => _isResending = false);
                                  }
                                }
                              },
                              child: Text(
                                l10n?.resendCodeLabel ?? 'Resend Code',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isCodeSent = false;
                        _emailController.clear();
                      });
                    },
                    child: Text(
                      l10n?.tryAnotherEmail ?? 'Try another email',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}