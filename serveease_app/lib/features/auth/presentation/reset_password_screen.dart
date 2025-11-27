// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/validators.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _token = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Retrieve email from route arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['email'] != null) {
      _email.text = args['email'];
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      await _auth.resetPassword(
        _token.text.trim(),
        _password.text.trim(),
        _email.text.trim(),
      );

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Password changed.')));

      Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                  'Enter the token sent to your email and choose a new password.'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _token,
                decoration: const InputDecoration(labelText: 'Reset Code'),
                validator: (v) => v == null || v.isEmpty ? 'Code required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
                validator: (v) => Validators.validatePassword(context, v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                validator: (v) =>
                    Validators.validateConfirmPassword(context, v, _password.text),
              ),
              const SizedBox(height: 18),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Reset Password'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
