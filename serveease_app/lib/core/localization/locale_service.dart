import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  static const String _localeKey = 'selected_locale';
  static const Locale _defaultLocale = Locale('en');

  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('am'), // Amharic
  ];

  static const Map<String, String> localeNames = {
    'en': 'English',
    'am': 'አማርኛ',
  };

  /// Get the current locale from shared preferences
  static Future<Locale> getCurrentLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(_localeKey);

    if (localeCode != null) {
      return Locale(localeCode);
    }

    return _defaultLocale;
  }

  /// Set the current locale and save to shared preferences
  static Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  /// Get the device locale if supported, otherwise return default
  static Locale getDeviceLocale() {
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;

    // Check if device locale is supported
    for (final supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == deviceLocale.languageCode) {
        return supportedLocale;
      }
    }

    return _defaultLocale;
  }

  /// Check if a locale is supported
  static bool isLocaleSupported(Locale locale) {
    return supportedLocales.any(
      (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
    );
  }

  /// Get locale name for display
  static String getLocaleName(Locale locale) {
    return localeNames[locale.languageCode] ?? locale.languageCode;
  }

  /// Get all supported locales with their display names
  static Map<Locale, String> getSupportedLocalesWithNames() {
    final Map<Locale, String> localesWithNames = {};

    for (final locale in supportedLocales) {
      localesWithNames[locale] = getLocaleName(locale);
    }

    return localesWithNames;
  }

  /// Initialize locale service
  static Future<Locale> initialize() async {
    final savedLocale = await getCurrentLocale();

    // If no saved locale, use device locale if supported
    if (savedLocale == _defaultLocale) {
      final deviceLocale = getDeviceLocale();
      if (deviceLocale != _defaultLocale) {
        await setLocale(deviceLocale);
        return deviceLocale;
      }
    }

    return savedLocale;
  }

  /// Check if the current locale is RTL (Right-to-Left)
  static bool isRTL(Locale locale) {
    // Add RTL language codes here if needed
    const rtlLanguages = ['ar', 'he', 'fa', 'ur'];
    return rtlLanguages.contains(locale.languageCode);
  }

  /// Get text direction for the locale
  static TextDirection getTextDirection(Locale locale) {
    return isRTL(locale) ? TextDirection.rtl : TextDirection.ltr;
  }
}
