import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2D6BED); // blue
  static const primaryGradientStart = Color(0xFF2D6BED);
  static const primaryGradientEnd = Color(0xFF1753D6);
  static const accent = Color(0xFF08A0F7);
  static const background = Colors.white;
  static const grey = Color(0xFFF2F4F7);
}

class AppTheme {
  static final lightTheme = ThemeData(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.grey,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
  );
}
