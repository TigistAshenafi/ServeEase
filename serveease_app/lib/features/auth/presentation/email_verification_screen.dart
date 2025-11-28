// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/language_toggle.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _code = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  String? _email;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _email = args?['email'];
  }

  void _verify() async {
    final l10n = context.l10n;

    if (_email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.missingEmailError)),
      );
      return;
    }

    if (_code.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.emptyVerificationCode)),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await _auth.verifyEmail(_email!, _code.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.emailVerifiedMessage),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorWithMessage('$e')),
          backgroundColor: Colors.red,
        ),
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
          child: Column(
            children: [
              // --- Language toggle ---
              const LanguageToggle(alignment: Alignment.centerRight),
              const SizedBox(height: 16),

              // --- Icon ---
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 60,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),

              // --- Title ---
              Text(
                l10n.verifyEmailTitle,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // --- Description ---
              if (_email != null)
                Text(
                  l10n.verifyEmailInfo(_email!),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),

              const SizedBox(height: 40),

              // --- Code Input ---
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.verificationCodeLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_clock_outlined),
                ),
              ),

              const SizedBox(height: 24),

              // --- Verify button ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          l10n.verifyButtonLabel,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 16),

              // --- Back to login ---
              GestureDetector(
                onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                child: Text(
                  l10n.backToLoginLabel,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
