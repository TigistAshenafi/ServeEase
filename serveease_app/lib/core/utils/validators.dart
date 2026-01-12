import 'package:email_validator/email_validator.dart';
import 'package:flutter/widgets.dart';
import 'package:serveease_app/l10n/app_localizations.dart';

class Validators {
  static String? validateEmail(BuildContext context, String? v) {
    final l10n = AppLocalizations.of(context)!;
    if (v == null || v.trim().isEmpty) {
      return l10n.validationEmailRequired;
    }
    if (!EmailValidator.validate(v.trim())) {
      return l10n.validationEmailInvalid;
    }
    return null;
  }

  static String? validatePassword(BuildContext context, String? v) {
    final l10n = AppLocalizations.of(context)!;
    if (v == null || v.isEmpty) {
      return l10n.validationPasswordRequired;
    }
    if (v.length < 6) {
      return l10n.validationPasswordLength;
    }
    return null;
  }

  static String? validateConfirmPassword(
    BuildContext context,
    String? v,
    String password,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (v == null || v.isEmpty) {
      return l10n.validationConfirmPassword;
    }
    if (v != password) {
      return l10n.validationPasswordsMismatch;
    }
    return null;
  }

  /// Validate required text fields
  static String? validateRequired(BuildContext context, String? v,
      [String? fieldName]) {
    final l10n = AppLocalizations.of(context)!;
    if (v == null || v.trim().isEmpty) {
      return l10n.validationRequired;
    }
    return null;
  }

  /// Validate phone number (basic validation)
  static String? validatePhone(BuildContext context, String? v) {
    final l10n = AppLocalizations.of(context)!;
    if (v == null || v.trim().isEmpty) {
      return l10n.validationPhoneRequired;
    }
    // Basic phone validation - can be enhanced based on requirements
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    if (!phoneRegex.hasMatch(v.trim())) {
      return l10n.validationPhoneInvalid;
    }
    return null;
  }

  /// Validate service price
  static String? validatePrice(BuildContext context, String? v) {
    final l10n = AppLocalizations.of(context)!;
    if (v == null || v.trim().isEmpty) {
      return l10n.validationPriceRequired;
    }
    final price = double.tryParse(v.trim());
    if (price == null || price <= 0) {
      return l10n.validationPriceInvalid;
    }
    return null;
  }

  /// Validate service duration
  static String? validateDuration(BuildContext context, String? v) {
    final l10n = AppLocalizations.of(context)!;
    if (v == null || v.trim().isEmpty) {
      return l10n.validationDurationRequired;
    }
    final duration = int.tryParse(v.trim());
    if (duration == null || duration <= 0) {
      return l10n.validationDurationInvalid;
    }
    return null;
  }

  /// Validate minimum length
  static String? validateMinLength(
      BuildContext context, String? v, int minLength,
      [String? fieldName]) {
    if (v == null || v.trim().isEmpty) {
      return validateRequired(context, v, fieldName);
    }
    if (v.trim().length < minLength) {
      return fieldName != null
          ? '$fieldName must be at least $minLength characters long'
          : 'Must be at least $minLength characters long';
    }
    return null;
  }

  /// Validate maximum length
  static String? validateMaxLength(
      BuildContext context, String? v, int maxLength,
      [String? fieldName]) {
    if (v != null && v.trim().length > maxLength) {
      return fieldName != null
          ? '$fieldName must be no more than $maxLength characters long'
          : 'Must be no more than $maxLength characters long';
    }
    return null;
  }

  /// Validate name (letters, spaces, and common punctuation only)
  static String? validateName(BuildContext context, String? v) {
    final l10n = AppLocalizations.of(context)!;
    if (v == null || v.trim().isEmpty) {
      return l10n.validationRequired;
    }
    // Allow letters, spaces, apostrophes, hyphens, and dots
    final nameRegex = RegExp(r"^[a-zA-Z\s\'\-\.]+$");
    if (!nameRegex.hasMatch(v.trim())) {
      return 'Please enter a valid name';
    }
    return null;
  }

  /// Validate business name
  static String? validateBusinessName(BuildContext context, String? v) {
    final l10n = AppLocalizations.of(context)!;
    if (v == null || v.trim().isEmpty) {
      return l10n.validationRequired;
    }
    if (v.trim().length < 2) {
      return 'Business name must be at least 2 characters long';
    }
    return null;
  }

  /// Validate service description
  static String? validateDescription(BuildContext context, String? v) {
    final l10n = AppLocalizations.of(context)!;
    if (v == null || v.trim().isEmpty) {
      return l10n.validationRequired;
    }
    if (v.trim().length < 10) {
      return 'Description must be at least 10 characters long';
    }
    if (v.trim().length > 500) {
      return 'Description must be no more than 500 characters long';
    }
    return null;
  }

  /// Validate verification code (6 digits)
  static String? validateVerificationCode(BuildContext context, String? v) {
    final l10n = AppLocalizations.of(context)!;
    if (v == null || v.trim().isEmpty) {
      return l10n.validationRequired;
    }
    if (v.trim().length != 6) {
      return 'Verification code must be 6 digits';
    }
    final codeRegex = RegExp(r'^\d{6}$');
    if (!codeRegex.hasMatch(v.trim())) {
      return 'Please enter a valid 6-digit code';
    }
    return null;
  }
}
