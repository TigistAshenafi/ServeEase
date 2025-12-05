// ignore_for_file: use_build_context_synchronously, unused_field, prefer_final_fields

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
  final TextEditingController _codeController = TextEditingController();
  final AuthService _auth = AuthService();

  bool _loading = false;
  String? _email;
  String? _password; // needed to auto-login
  String? _role;
  bool _verified = false; // prevents double submit

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    _email = args?['email'];
    _password = args?['password']; // pass password from signup
    _role = args?['role'];
  }

void _verify() async {
  final l10n = context.l10n;

  if (_email == null || _codeController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.missingEmailError)),
    );
    return;
  }

  setState(() => _loading = true);

  try {
    final res = await _auth.verifyEmail(_email!, _codeController.text.trim());
    
    // Save token if provider
    final role = res.data['role'];
    final token = res.data['accessToken'];
    if (token != null) await _auth.saveAccessToken(token);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.emailVerifiedMessage),
        backgroundColor: Colors.green,
      ),
    );

    if (role == 'provider') {
      Navigator.pushReplacementNamed(
        context,
        '/provider-setup',
        arguments: {'email': _email},
      );
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
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
              const LanguageToggle(alignment: Alignment.centerRight),
              const SizedBox(height: 16),
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 60,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.verifyEmailTitle,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_email != null)
                Text(
                  l10n.verifyEmailInfo(_email!),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              const SizedBox(height: 40),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.verificationCodeLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_clock_outlined),
                ),
              ),
              const SizedBox(height: 24),
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
