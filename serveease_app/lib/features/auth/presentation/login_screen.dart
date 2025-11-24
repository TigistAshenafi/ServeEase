// ignore_for_file: use_build_context_synchronously

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/guards/auth_guard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _isPasswordVisible = false;

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

  void _login() async {
    // VALIDATION FIRST
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

   try {
  await _authService.login(
    _emailController.text.trim(),
    _passwordController.text.trim(),
  );

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Login successful!"),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 2),
    ),
  );

  Navigator.pushReplacementNamed(context, '/home');
}
 catch (e) {
  String msg;

if (e is DioException) {
  // If DioException has a response with data['message'], use it; otherwise fallback
  msg = e.response != null && e.response?.data != null && e.response?.data['message'] != null
      ? e.response!.data['message'].toString()
      : e.message ?? 'Unknown error';
} else {
  msg = e.toString();
}

// Then show SnackBar
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text("Login failed: $msg"),
    backgroundColor: Colors.red,
    duration: const Duration(seconds: 3),
  ),
);}
 finally {
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
                const Icon(
                  Icons.diamond_outlined,
                  size: 60,
                  color: Colors.blue,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Welcome Back",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Log in to continue using ServeEase",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // EMAIL FIELD
                TextFormField(
                  controller: _emailController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email Address",
                    hintText: "you@example.com",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Email is required";
                    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
                    if (!emailRegex.hasMatch(value)) return "Enter a valid email address";
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // PASSWORD FIELD
                TextFormField(
                  controller: _passwordController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() => _isPasswordVisible = !_isPasswordVisible);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Password is required";
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // FORGOT PASSWORD
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/forgot-password'),
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // LOGIN BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Log In",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                // SIGNUP REDIRECT
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, '/signup'),
                  child: const Text.rich(
                    TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(color: Colors.grey),
                      children: [
                        TextSpan(
                          text: "Sign Up",
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
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
