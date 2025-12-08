<<<<<<< HEAD
// ignore_for_file: use_build_context_synchronously, unused_field, avoid_print
=======
// ignore_for_file: use_build_context_synchronously, unused_field
>>>>>>> 2ed092fc1254d94369395abb57da6ada1177124c

import 'package:flutter/material.dart';

import '../../../core/guards/auth_guard.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/language_toggle.dart';

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
    setState(() => _loading = true); // 🔥 enable validation AFTER submit

    if (!_formKey.currentState!.validate()) return;

    try {
      final response = await AuthService().login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      print("Login response: ${response.data}");

      final token = response.data['accessToken'];
      print("Login response: ${response.data}");

      if (token != null) {
        await AuthService().saveAccessToken(token);
        print("Token saved successfully.");
      } else {
        print("No access token in response");
        return;
      }

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      print("LOGIN ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
             autovalidateMode: _loading
                ? AutovalidateMode.always   // 🔥 Show validation after submit
                : AutovalidateMode.disabled, // 🔥 Hide before submit
            child: Column(
              children: [
                // --- Language toggle at top right ---
                const LanguageToggle(alignment: Alignment.centerRight),
                const SizedBox(height: 16),

                // --- Logo ---
                const Icon(
                  Icons.diamond_outlined,
                  size: 60,
                  color: Colors.blue,
                ),
                const SizedBox(height: 20),

                // --- Titles ---
                Text(
                  l10n.loginWelcomeTitle,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.loginSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // --- Email field ---
                TextFormField(
                  controller: _emailController,
                  autovalidateMode:
                      AutovalidateMode.disabled, // only validate on submit
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.emailLabel,
                    hintText: l10n.emailHint,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (value) =>
                      Validators.validateEmail(context, value),
                  onChanged: (_) => setState(() {}), // simple and effective
                ),
                const SizedBox(height: 16),

                // --- Password field ---
                TextFormField(
                  controller: _passwordController,
                  autovalidateMode: AutovalidateMode.disabled,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: l10n.passwordLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  validator: (value) =>
                      Validators.validatePassword(context, value),
                ),
                const SizedBox(height: 12),

                // --- Forgot password ---
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, '/forgot-password'),
                    child: Text(
                      l10n.forgotPasswordLabel,
                      style: const TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- Login button ---
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
                          child: Text(
                            l10n.loginButtonLabel,
                            style: const TextStyle(
                                fontSize: 18, color: Colors.white),
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // --- Signup redirect ---
                GestureDetector(
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/signup'),
                  child: Text.rich(
                    TextSpan(
                      text: l10n.signupRedirectPrefix,
                      style: const TextStyle(color: Colors.grey),
                      children: [
                        TextSpan(
                          text: l10n.signupRedirectAction,
                          style: const TextStyle(
                              color: Colors.blue, fontWeight: FontWeight.bold),
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
