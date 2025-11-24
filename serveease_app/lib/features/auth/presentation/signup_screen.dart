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
                ),

                const SizedBox(height: 16),

                // EMAIL
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(
                    labelText: "Email Address",
                    hintText: "you@example.com",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) => Validators.validateEmail(v),
                ),

                const SizedBox(height: 16),

                // PASSWORD
                TextFormField(
                  controller: _password,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (v) => Validators.validatePassword(v),
                ),

                const SizedBox(height: 16),

                // CONFIRM PASSWORD
                TextFormField(
                  controller: _confirm,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_isConfirmPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (v) =>
                      Validators.validateConfirmPassword(v, _password.text),
                ),

                const SizedBox(height: 24),

                // ROLE SELECTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Radio<Role>(
                      value: Role.seeker,
                      groupValue: _role,
                      onChanged: (r) => setState(() => _role = r!),
                    ),
                    const Text("Service Seeker"),
                    const SizedBox(width: 20),
                    Radio<Role>(
                      value: Role.provider,
                      groupValue: _role,
                      onChanged: (r) => setState(() => _role = r!),
                    ),
                    const Text("Service Provider"),
                  ],
                ),

                const SizedBox(height: 20),

                // SIGN UP BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _signup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Sign Up",
                            style:
                                TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                // LOGIN LINK
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text.rich(
                    TextSpan(
                      text: "Already have an account? ",
                      style: TextStyle(color: Colors.grey),
                      children: [
                        TextSpan(
                          text: "Log In",
                          style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
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
