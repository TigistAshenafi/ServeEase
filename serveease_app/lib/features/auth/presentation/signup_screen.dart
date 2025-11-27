// ignore_for_file: use_build_context_synchronously, deprecated_member_use, unused_local_variable

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/guards/auth_guard.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/language_toggle.dart';
import '../../../shared/widgets/role_selector.dart';

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
  final _businessName = TextEditingController();
  final _businessDescription = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Role _role = Role.seeker;
  bool get _isProvider => _role == Role.provider;
  final _auth = AuthService();
  bool _loading = false;
  final _formKey = GlobalKey<FormState>();

  // <-- Added initState and _checkAuth
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
    _businessName.dispose();
    _businessDescription.dispose();
    super.dispose();
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
    final l10n = context.l10n;
    try {
      final roleStr = _isProvider ? 'provider' : 'seeker';
      final providerProfile = _isProvider
          ? {
              'businessName': _businessName.text.trim(),
              'description': _businessDescription.text.trim(),
            }
          : null;
      await _auth.register(
        _email.text.trim(),
        _password.text.trim(),
        roleStr,
        name: _name.text.trim(),
        providerProfile: providerProfile,
      );

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/verify-email',
        arguments: {'email': _email.text.trim()},
      );
    } on DioException catch (e) {
      final msg =
          e.response?.data?['message'] ?? e.message ?? l10n.unknownError;
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorWithMessage(msg))));
    } finally {
      if (mounted) setState(() => _loading = false);
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
            child: Column(
              children: [
                const LanguageToggle(alignment: Alignment.centerRight),
                const SizedBox(height: 16),
                const Icon(Icons.diamond_outlined,
                    size: 60, color: Colors.blue),
                const SizedBox(height: 20),

                Text(
                  l10n.createAccountTitle,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),
                Text(
                  l10n.signupSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 30),

                // FULL NAME
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: l10n.nameOptionalLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  decoration: InputDecoration(
                    labelText: l10n.emailLabel,
                    hintText: l10n.emailHint,
                  ),
                  validator: (v) => Validators.validateEmail(context, v),
                ),

                const SizedBox(height: 16),

                // PASSWORD
                TextFormField(
                  controller: _password,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: l10n.passwordLabel,
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
                  validator: (v) => Validators.validatePassword(context, v),
                ),
                const SizedBox(height: 16),

                // CONFIRM PASSWORD
                TextFormField(
                  controller: _confirm,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: l10n.confirmPasswordLabel,
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
                  validator: (v) => Validators.validateConfirmPassword(
                      context, v, _password.text),
                ),

                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(l10n.joinAsLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                RoleSelector(
                    selected: _role,
                    onChanged: (r) => setState(() => _role = r)),
                if (_isProvider) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.providerDetailsTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _businessName,
                    decoration: InputDecoration(
                      labelText: l10n.businessNameLabel,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.storefront_outlined),
                    ),
                    validator: (v) {
                      if (!_isProvider) return null;
                      if (v == null || v.trim().isEmpty) {
                        return l10n.providerBusinessValidation;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _businessDescription,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: l10n.serviceDescriptionLabel,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.description_outlined),
                    ),
                    validator: (v) {
                      if (!_isProvider) return null;
                      if (v == null || v.trim().isEmpty) {
                        return l10n.providerDescriptionValidation;
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 24),
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
                            _isProvider
                                ? l10n.signupSubmitLabel
                                : l10n.signupSubmitLabel,
                            style: TextStyle(fontSize: 18, color: Colors.white),
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
                      text: (l10n.loginRedirectPrefix),
                      style: const TextStyle(color: Colors.grey),
                      children: [
                        TextSpan(
                          text: (l10n.loginRedirectAction),
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
