// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../shared/widgets/role_selector.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/validators.dart';

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
  Role _role = Role.seeker;
  final _auth = AuthService();
  bool _loading = false;
  final _formKey = GlobalKey<FormState>();

  void _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final roleStr = _role == Role.seeker ? 'seeker' : 'provider';
      await _auth.register(_email.text.trim(), _password.text.trim(), roleStr,
          name: _name.text.trim());
      // navigate to verify email page
      Navigator.pushNamed(context, '/email-verification',
          arguments: {'email': _email.text.trim()});
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $msg')));
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  const FlutterLogo(size: 72),
                  const SizedBox(height: 16),
                  const Text('Create Your Account',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                      'Join ServeEase to connect with services or offer your expertise.',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                        labelText: 'Full name (optional)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    decoration:
                        const InputDecoration(labelText: 'Email Address'),
                    validator: (v) => Validators.validateEmail(v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (v) => Validators.validatePassword(v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirm,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Confirm Password'),
                    validator: (v) =>
                        Validators.validateConfirmPassword(v, _password.text),
                  ),
                  const SizedBox(height: 12),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Join as:',
                          style: TextStyle(fontWeight: FontWeight.w600))),
                  const SizedBox(height: 8),
                  RoleSelector(
                      selected: _role,
                      onChanged: (r) => setState(() => _role = r)),
                  const SizedBox(height: 18),
                  _loading
                      ? const CircularProgressIndicator()
                      : CustomButton(label: 'Sign Up', onPressed: _signup),
                  const SizedBox(height: 12),
                  TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      child: const Text('Already have an account? Log In')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
