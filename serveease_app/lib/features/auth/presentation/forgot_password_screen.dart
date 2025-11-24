// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

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

<<<<<<< HEAD
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "If an account exists, we have sent instructions to your email."),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
=======
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password reset link sent via your email.')));
      Navigator.pushNamed(
        context,
        '/reset-password',
        arguments: {'email': _email.text.trim()},
      );
    } catch (e) {
      if(!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
>>>>>>> feat/providerMgmt
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // ICON
                const Icon(
                  Icons.lock_reset,
                  size: 60,
                  color: Colors.blue,
                ),
                const SizedBox(height: 20),

                // Title
                const Text(
                  "Forgot Password?",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),
                const Text(
                  "Enter your email and we'll send you instructions\nto reset your password.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 30),

                // EMAIL FIELD
                TextFormField(
=======
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text('Enter your email to receive a password reset code.'),
              const SizedBox(height: 12),
              TextFormField(
>>>>>>> feat/providerMgmt
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
<<<<<<< HEAD
                    labelText: "Email Address",
                    hintText: "you@example.com",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) => Validators.validateEmail(v),
                ),

                const SizedBox(height: 24),

                // SUBMIT BUTTON
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
                          child: const Text(
                            "Send Reset Link",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text.rich(
                    TextSpan(
                      text: "Remembered your password? ",
                      style: TextStyle(color: Colors.grey),
                      children: [
                        TextSpan(
                          text: "Log In",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
=======
                    labelText: 'Email',
                    hintText: "you@example.com",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                    ),
                  validator: (v) => Validators.validateEmail(v)),
              const SizedBox(height: 24),
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
                      child: const Text(
                        'Send Reset Code',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
              ),

              const SizedBox(height: 16),

              GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text.rich(
                  TextSpan(
                    text: "Remembered your password? ",
                    style: TextStyle(color: Colors.grey),
                    children: [
                      TextSpan(
                        text: 'Back to Login',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
>>>>>>> feat/providerMgmt
          ),
        ),
      ),
    );
  }
}
