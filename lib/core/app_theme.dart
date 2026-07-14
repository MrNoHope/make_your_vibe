import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData dark() {
    return _base(
      brightness: Brightness.dark,
      background: AppColors.background,
      background2: AppColors.background2,
      panel: AppColors.panel,
      text: AppColors.text,
      soft: AppColors.soft,
      muted: AppColors.muted,
    );
  }

  static ThemeData light() {
    return _base(
      brightness: Brightness.light,
      background: const Color(0xFFF4F8F3),
      background2: const Color(0xFFFFFFFF),
      panel: const Color(0xFFFFFFFF),
      text: const Color(0xFF101610),
      soft: const Color(0xFF4F5C50),
      muted: const Color(0xFF7B887C),
    );
  }

  static ThemeData _base({
    required Brightness brightness,
    required Color background,
    required Color background2,
    required Color panel,
    required Color text,
    required Color soft,
    required Color muted,
  }) {
    final dark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.green,
        brightness: brightness,
        primary: AppColors.green,
        secondary: AppColors.green2,
        surface: panel,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: text,
          fontSize: 31,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
        ),
        headlineMedium: TextStyle(
          color: text,
          fontSize: 25,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
        titleMedium: TextStyle(
          color: text,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        bodyLarge: TextStyle(
          color: soft,
          fontSize: 15,
        ),
        bodyMedium: TextStyle(
          color: soft,
          fontSize: 13,
        ),
        bodySmall: TextStyle(
          color: muted,
          fontSize: 11,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? AppColors.panel2 : const Color(0xFFE8EFE8),
        hintStyle: TextStyle(color: muted),
        prefixIconColor: soft,
        suffixIconColor: soft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.green,
          side: BorderSide(
            color: dark ? AppColors.line : const Color(0xFFD4DED4),
          ),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
