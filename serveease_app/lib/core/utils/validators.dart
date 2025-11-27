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
}
