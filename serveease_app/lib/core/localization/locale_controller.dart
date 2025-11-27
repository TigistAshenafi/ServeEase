import 'package:flutter/material.dart';

class LocaleController extends ChangeNotifier {
  static const supportedLocales = [
    Locale('en'),
    Locale('am'),
  ];
  Locale? _locale;

  Locale? get locale => _locale;

  void setLocale(Locale locale) {
    final isSupported = supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
    if (!isSupported) return;

    if (locale == _locale) return;
    _locale = locale;
    notifyListeners();
  }
}

final localeController = LocaleController();
