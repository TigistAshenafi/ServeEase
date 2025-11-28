// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:serveease_app/core/localization/l10n_extension.dart';
import 'package:serveease_app/shared/widgets/language_toggle.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/validators.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  final _formKey = GlobalKey<FormState>();

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await _auth.requestPasswordReset(_email.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.resetCodeSentMessage),
        ),
      );

      Navigator.pushNamed(
        context,
        '/reset-password',
        arguments: {'email': _email.text.trim()},
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _loading = false);
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
                // Language toggle
                const LanguageToggle(alignment: Alignment.centerRight),
                const SizedBox(height: 16),

                // Icon
                const Icon(Icons.lock_reset, size: 60, color: Colors.blue),
                const SizedBox(height: 20),

                // Title & subtitle
                Text(
                  l10n.forgotPasswordTitle,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.forgotPasswordSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 30),

                // Email input
                TextFormField(
                  controller: _email,
                  autovalidateMode: AutovalidateMode.disabled,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.emailLabel,
                    hintText: l10n.emailHint,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (value) => Validators.validateEmail(context, value),
                ),
                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            l10n.sendResetLinkButton, // localized
                            style: const TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Back to login
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: Text.rich(
                    TextSpan(
                      text: l10n.rememberPasswordPrefix,
                      style: const TextStyle(color: Colors.grey),
                      children: [
                        TextSpan(
                          text: l10n.rememberPasswordAction,
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
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
