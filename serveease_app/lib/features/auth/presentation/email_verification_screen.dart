// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';

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
          .showSnackBar(const SnackBar(content: Text('Missing email')));
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.verifyEmail(_email!, _code.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified. Please log in.')));
      Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_email != null)
              Text('A verification code was sent to $_email',
                  textAlign: TextAlign.center),
            const SizedBox(height: 18),
            TextField(
                controller: _code,
                decoration:
                    const InputDecoration(labelText: 'Verification code')),
            const SizedBox(height: 18),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _verify, child: const Text('Verify')),
          ],
        ),
      ),
    );
  }
}
