// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/language_toggle.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<EmailVerificationScreen> {
  final _code = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  String? _email;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _email = args != null ? args['email'] as String? : null;
  }

  void _verify() async {
    if (_email == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.missingEmailError)));
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.verifyEmail(_email!, _code.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.emailVerifiedMessage)));
      Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.errorWithMessage('$e'))),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.verifyEmailTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const LanguageToggle(alignment: Alignment.centerRight),
            const SizedBox(height: 16),
            if (_email != null)
              Text(l10n.verifyEmailInfo(_email!),
                  textAlign: TextAlign.center),
            const SizedBox(height: 18),
            TextField(
                controller: _code,
                decoration:
                    InputDecoration(labelText: l10n.verificationCodeLabel)),
            const SizedBox(height: 18),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _verify, child: Text(l10n.verifyButtonLabel)),
          ],
        ),
      ),
    );
  }
}
