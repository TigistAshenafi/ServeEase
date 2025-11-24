// ignore_for_file: use_build_context_synchronously

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/role_selector.dart';
import '../../../core/guards/auth_guard.dart'; // <-- added import

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _name = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Role _role = Role.seeker;
  final _auth = AuthService();
  bool _loading = false;
  final _formKey = GlobalKey<FormState>();

  // <-- Added initState and _checkAuth
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    final loggedIn = await AuthGuard.isLoggedIn();
    if (loggedIn && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }
  // <-- End addition

  void _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final roleStr = _role == Role.seeker ? 'seeker' : 'provider';
      await _auth.register(
        _email.text.trim(),
        _password.text.trim(),
        roleStr,
        name: _name.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/email-verification',
        arguments: {'email': _email.text.trim()},
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message;
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $msg')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.diamond_outlined, size: 60, color: Colors.blue),
                const SizedBox(height: 20),

                const Text(
                  "Create Your Account",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),
                const Text(
                  "Join ServeEase to connect with services or offer your expertise.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 30),

                // FULL NAME
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: "Full Name (optional)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    decoration:
                        const InputDecoration(labelText: 'Email Address'),
                    validator: (v) => Validators.validateEmail(v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (v) => Validators.validatePassword(v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirm,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Confirm Password'),
                    validator: (v) =>
                        Validators.validateConfirmPassword(v, _password.text),
                  ),
                  const SizedBox(height: 12),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Join as:',
                          style: TextStyle(fontWeight: FontWeight.w600))),
                  const SizedBox(height: 8),
                  RoleSelector(
                      selected: _role,
                      onChanged: (r) => setState(() => _role = r)),
                  const SizedBox(height: 18),
                  _loading
                      ? const CircularProgressIndicator()
                      : CustomButton(label: 'Sign Up', onPressed: _signup),
                  const SizedBox(height: 12),
                  TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      child: const Text('Already have an account? Log In')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
