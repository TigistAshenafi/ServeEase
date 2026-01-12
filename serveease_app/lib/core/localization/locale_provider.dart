import 'package:flutter/material.dart';
import 'locale_service.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;

  /// Initialize the locale provider
  Future<void> initialize() async {
    _currentLocale = await LocaleService.initialize();
    notifyListeners();
  }

  /// Change the current locale
  Future<void> setLocale(Locale locale) async {
    if (!LocaleService.isLocaleSupported(locale)) {
      return;
    }

    _currentLocale = locale;
    await LocaleService.setLocale(locale);
    notifyListeners();
  }

  /// Toggle between English and Amharic
  Future<void> toggleLocale() async {
    final newLocale = _currentLocale.languageCode == 'en'
        ? const Locale('am')
        : const Locale('en');

    await setLocale(newLocale);
  }

  /// Get text direction for current locale
  TextDirection get textDirection =>
      LocaleService.getTextDirection(_currentLocale);

  /// Check if current locale is RTL
  bool get isRTL => LocaleService.isRTL(_currentLocale);

  /// Get current locale display name
  String get currentLocaleName => LocaleService.getLocaleName(_currentLocale);

  /// Get all supported locales with names
  Map<Locale, String> get supportedLocalesWithNames =>
      LocaleService.getSupportedLocalesWithNames();
}
