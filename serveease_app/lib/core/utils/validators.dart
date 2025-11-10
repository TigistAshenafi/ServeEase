import 'package:email_validator/email_validator.dart';

class Validators {
  static String? validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (!EmailValidator.validate(v.trim())) return 'Invalid email';
    return null;
  }

  static String? validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? validateConfirmPassword(String? v, String password) {
    if (v == null || v.isEmpty) return 'Confirm password';
    if (v != password) return 'Passwords do not match';
    return null;
  }
}
