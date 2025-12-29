// lib/screens/verify_email_screen.dart
// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serveease_app/core/models/user_model.dart';
import 'package:serveease_app/providers/auth_provider.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  String? _email;
  String? _userRole;
  bool _isLoading = false;
  int _resendTimer = 60; // 60 seconds timer
  bool _canResend = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _setupFocusListeners();
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _email = args?['email'];
    _userRole = args?['role'];
  }

  void _setupFocusListeners() {
    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].addListener(() {
        if (_controllers[i].text.isNotEmpty && i < _controllers.length - 1) {
          _focusNodes[i + 1].requestFocus();
        }
      });
    }
  }

  void _startTimer() {
    _canResend = false;
    _resendTimer = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  void _stopTimer() {
    if (_timer.isActive) {
      _timer.cancel();
    }
  }

  String _getVerificationCode() {
    return _controllers.map((c) => c.text).join();
  }

  Future<void> _verifyEmail() async {
    if (_email == null) {
      _showError('Email not found');
      return;
    }

    final code = _getVerificationCode();
    if (code.length != 6) {
      _showError('Please enter the 6-digit code');
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final response = await authProvider.verifyEmail(
      email: _email!,
      code: code,
    );
    
    setState(() => _isLoading = false);

    if (response.success && response.data != null) {
      await _handleSuccessfulVerification(response.data!, authProvider);
    } else {
      _showError(response.message);
    }
  }

  Future<void> _handleSuccessfulVerification(User user, AuthProvider authProvider) async {
    _showSuccess('Email verified successfully!');
    
    await Future.delayed(const Duration(milliseconds: 1500));
    
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
      arguments: {
        'email': _email,
        'message': 'Email verified successfully! Please login to continue.',
        'redirectTo': user.role == 'provider' ? '/provider/create-profile' : '/home',
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _resendCode() async {
    if (_email == null) {
      _showError('Email not found');
      return;
    }

    if (!_canResend) return;

    setState(() => _isLoading = true);
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final response = await authProvider.resendVerificationCode(_email!);
    
    setState(() => _isLoading = false);
    
    if (response.success) {
      _showSuccess('Verification code resent successfully! Check your email.');
      _startTimer(); // Restart the timer
    } else {
      _showError(response.message ?? 'Failed to resend code');
    }
  }

  @override
  void dispose() {
    _stopTimer();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 20),

                // Header Section
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.verified_user_outlined,
                      size: 60,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Title
                Center(
                  child: Text(
                    'Verify Your Email',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Description
                Center(
                  child: Text(
                    'We sent a 6-digit verification code to',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Email Display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.email_outlined, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _email ?? 'email@example.com',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                
                // User Role Info
                if (_userRole != null)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _userRole == 'provider'
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _userRole == 'provider' ? Icons.work : Icons.person,
                            size: 16,
                            color: _userRole == 'provider'
                                ? Colors.orange.shade700
                                : Colors.green.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _userRole == 'provider' ? 'Service Provider' : 'Service Seeker',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _userRole == 'provider'
                                  ? Colors.orange.shade700
                                  : Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                
                // Code Input Section
                Text(
                  'Enter 6-digit Code',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Code Input Fields with Auto Focus Management
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 48,
                      height: 48,
                      child: TextFormField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: colorScheme.primary, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          } else if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                          
                          // Auto-submit when last digit is entered
                          if (value.isNotEmpty && index == 5) {
                            // Submit after a small delay
                            Future.delayed(const Duration(milliseconds: 300), () {
                              _verifyEmail();
                            });
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                
                // Timer Display
                Center(
                  child: Text(
                    _canResend
                        ? 'You can resend the code now'
                        : 'Resend code in $_resendTimer seconds',
                    style: TextStyle(
                      color: _canResend
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Action Buttons
                if (_isLoading)
                  Center(
                    child: CircularProgressIndicator(color: colorScheme.primary),
                  )
                else
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _verifyEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'VERIFY EMAIL',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Resend Code Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Didn't receive the code? ",
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                          GestureDetector(
                            onTap: _canResend ? _resendCode : null,
                            child: Text(
                              'RESEND CODE',
                              style: TextStyle(
                                color: _canResend
                                    ? colorScheme.primary
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Timer Progress Bar
                      if (!_canResend)
                        SizedBox(
                          width: double.infinity,
                          height: 4,
                          child: LinearProgressIndicator(
                            value: _resendTimer / 60,
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                          ),
                        ),
                      
                      if (_canResend) const SizedBox(height: 20),
                      
                      // Back to Login Button
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: Text(
                            'Back to Login',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                
                // Info Box
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.surfaceContainerHighest.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verification Note',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '• Check your spam folder if you don\'t see the email\n'
                              '• Code expires in 10 minutes\n'
                              '• You can resend the code after 60 seconds',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}