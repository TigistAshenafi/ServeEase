import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:serveease_app/l10n/app_localizations.dart';
import 'package:serveease_app/providers/auth_provider.dart';
import 'package:serveease_app/shared/widgets/app_bar_language_toggle.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _codeControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _codeFocusNodes = List.generate(6, (_) => FocusNode());
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _email;
  bool _isResending = false; // Added for resend button loading state

  @override
  void initState() {
    super.initState();
    _setupFocusListeners();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _email = args?['email'];
  }

  void _setupFocusListeners() {
    for (int i = 0; i < _codeControllers.length; i++) {
      _codeControllers[i].addListener(() {
        if (_codeControllers[i].text.isNotEmpty && i < _codeControllers.length - 1) {
          _codeFocusNodes[i + 1].requestFocus();
        }
      });
    }
  }

  String _getVerificationCode() => _codeControllers.map((c) => c.text).join();

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      final l10n = AppLocalizations.of(context);
      
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.validationPasswordsMismatch ?? 'Passwords do not match'), 
            backgroundColor: Colors.red
          ),
        );
        return;
      }

      final code = _getVerificationCode();
      if (code.length != 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.emptyVerificationCode ?? 'Please enter the complete 6-digit code'), 
            backgroundColor: Colors.red
          ),
        );
        return;
      }

      if (_email == null || _email!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.validationEmailRequired ?? 'Email is required'), 
            backgroundColor: Colors.red
          ),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await authProvider.resetPassword(
        email: _email!,
        code: code,
        newPassword: _passwordController.text,
      );

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.emailVerifiedMessage ?? 'Password reset successfully!'), 
            backgroundColor: Colors.green, 
            duration: const Duration(seconds: 3)
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _resendCode() async {
    if (_email != null && _email!.isNotEmpty) {
      setState(() => _isResending = true);
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.forgotPassword(_email!);
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.resetCodeSentMessage ?? 'Code resent successfully'), 
              backgroundColor: Colors.green
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isResending = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _codeFocusNodes) {
      node.dispose();
    }
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
        title: Text(l10n?.forgotPasswordTitle ?? 'Reset Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Language toggle
              const AppBarLanguageToggle(),
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
                  l10n?.forgotPasswordTitle ?? 'Reset Password',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 8.h),
              
              // Description text
              Text(
                _email != null 
                    ? 'A verification code was sent to $_email.'
                    : (l10n?.emptyVerificationCode ?? 'Please enter the 6-digit code'),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),

              // Verification code input - Updated styling
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48.w,
                    height: 48.h,
                    child: TextFormField(
                      controller: _codeControllers[index],
                      focusNode: _codeFocusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      decoration: InputDecoration(
                        counterText: '',
                        border: const OutlineInputBorder(),
                        filled: false, // Removed filled background
                      ),
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _codeFocusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _codeFocusNodes[index - 1].requestFocus();
                        }
                      },
                      validator: (value) => (value == null || value.isEmpty) ? '' : null,
                    ),
                  );
                }),
              ),
              SizedBox(height: 32.h),

              // New Password - Updated styling
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: l10n?.passwordLabel ?? 'New Password',
                  hintText: l10n?.passwordHint ?? 'Enter your new password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n?.validationPasswordRequired ?? 'Please enter new password';
                  }
                  if (value.length < 6) {
                    return l10n?.validationPasswordLength ?? 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.h),

              // Confirm Password - Updated styling
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: l10n?.confirmPasswordLabel ?? 'Confirm Password',
                  hintText: l10n?.passwordHint ?? 'Confirm your new password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n?.validationConfirmPassword ?? 'Please confirm password';
                  }
                  if (value != _passwordController.text) {
                    return l10n?.validationPasswordsMismatch ?? 'Passwords do not match';
                  }
                  return null;
                },
              ),
              SizedBox(height: 32.h),

              // Reset Button - Styled similar to Login
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 2,
                  ),
                  child: authProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          l10n?.forgotPasswordTitle ?? 'Reset Password',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 16.h),

              // Resend Code / Try another email - Fully Localized
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
                          onPressed: _resendCode,
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
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/forgot-password',
                    (route) => false,
                  ),
                  child: Text(
                    l10n?.tryAnotherEmail ?? 'Try another email',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}