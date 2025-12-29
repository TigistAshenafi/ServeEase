// lib/screens/forgot_password_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serveease_app/providers/auth_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Added for consistency

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
  final bool _obscurePassword = true; // Added for password visibility toggle
  bool _isResending = false; // for resend code loading

  Future<void> _sendResetCode() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final response = await authProvider.forgotPassword(email);

      if (response.success) {
        setState(() {
          _isCodeSent = true;
          _sentEmail = email;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reset code sent to your email'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
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

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Forgot Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h), // Updated padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                'Forgot Password?',
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
                  : 'Enter your email address and we\'ll send you a verification code to reset your password.',
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
                      labelText: 'Email Address',
                      hintText: 'Enter your email',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: false, // Removed grey background
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your email';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Please enter a valid email';
                      return null;
                    },
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
                          'Send Reset Code',
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
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Back to Login',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                        'Didn\'t receive the code? ',
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Code resent successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } finally {
                                    if (mounted) setState(() => _isResending = false);
                                  }
                                }
                              },
                              child: Text(
                                'Resend Code',
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
                      'Try another email',
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