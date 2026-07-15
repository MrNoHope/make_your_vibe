import 'package:flutter/material.dart';

import 'app_colors.dart';

ThemeData buildAppTheme({required Brightness brightness}) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.green,
    brightness: brightness,
  ).copyWith(
    primary: AppColors.green,
    secondary: AppColors.green2,
    surface: dark ? AppColors.panel : const Color(0xFFF8FBF7),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(46, 46),
      ),
    ),
    sliderTheme: const SliderThemeData(
      trackHeight: 4,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 22),
    ),
    listTileTheme: const ListTileThemeData(
      minVerticalPadding: 8,
      iconColor: AppColors.soft,
    ),
    colorScheme: scheme,
    scaffoldBackgroundColor:
        dark ? AppColors.background : const Color(0xFFF5F8F4),
    fontFamily: 'sans-serif',
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: dark ? AppColors.text : const Color(0xFF101611),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: dark ? AppColors.card : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: dark ? AppColors.line : const Color(0xFFE1E9E0),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? AppColors.card2 : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: dark ? AppColors.line : const Color(0xFFE1E9E0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.green, width: 1.4),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.black,
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? AppColors.background2 : Colors.white,
      indicatorColor: AppColors.green.withValues(alpha: 0.18),
    ),
  );
}
