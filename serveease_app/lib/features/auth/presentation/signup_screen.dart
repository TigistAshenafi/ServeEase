// ignore_for_file: use_build_context_synchronously

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/guards/auth_guard.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/language_toggle.dart';
import '../../../shared/widgets/role_selector.dart';
import 'package:serveease_app/l10n/app_localizations.dart';

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
  bool get _isProvider => _role == Role.provider;

  final _auth = AuthService();
  bool _loading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _name.dispose();
    super.dispose();
  }

  void _checkAuth() async {
    final loggedIn = await AuthGuard.isLoggedIn();
    if (loggedIn && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final roleStr = _isProvider ? 'provider' : 'seeker';

      await _auth.register(
        _email.text.trim(),
        _password.text.trim(),
        roleStr,
        name: _name.text.trim(),
      );

      if (!mounted) return;

      _password.clear();
      _confirm.clear();

      Navigator.pushNamed(
        context,
        '/verify-email',
        arguments: {
          'email': _email.text.trim(),
          'role': roleStr,
        },
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ??
          e.message ??
          AppLocalizations.of(context)!.unknownError;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const LanguageToggle(alignment: Alignment.centerRight),
                const SizedBox(height: 16),
                const Icon(Icons.diamond_outlined, size: 60, color: Colors.blue),
                const SizedBox(height: 20),
                Text(
                  loc.createAccountTitle,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.signupSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),

                // NAME
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: loc.nameLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? loc.nameValidation : null,
                ),
                const SizedBox(height: 16),

                // EMAIL
                TextFormField(
                  controller: _email,
                  decoration: InputDecoration(
                    labelText: loc.emailLabel,
                    hintText: loc.emailHint,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return loc.validationEmailRequired;
                    }
                    return Validators.validateEmail(context, v);
                  },
                ),
                const SizedBox(height: 16),

                // PASSWORD
                TextFormField(
                  controller: _password,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: loc.passwordLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? loc.validationPasswordRequired
                      : (v.length < 6)
                          ? loc.validationPasswordLength
                          : null,
                ),
                const SizedBox(height: 16),

                // CONFIRM PASSWORD
                TextFormField(
                  controller: _confirm,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: loc.confirmPasswordLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_isConfirmPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(
                          () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? loc.validationConfirmPassword
                      : (v != _password.text)
                          ? loc.validationPasswordsMismatch
                          : null,
                ),
                const SizedBox(height: 24),

                // ROLE SELECTOR
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    loc.joinAsLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),

                RoleSelector(
                  selected: _role,
                  onChanged: (r) => setState(() => _role = r),
                ),

                // PROVIDER NOTE
                if (_isProvider)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      loc.providerInfoNote,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),

                const SizedBox(height: 24),

                // SUBMIT BUTTON
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
                          child: Text(
                            loc.signupSubmitLabel,
                            style: const TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                // LOGIN LINK
                GestureDetector(
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: Text.rich(
                    TextSpan(
                      text: loc.loginRedirectPrefix,
                      style: const TextStyle(color: Colors.grey),
                      children: [
                        TextSpan(
                          text: loc.loginRedirectAction,
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
