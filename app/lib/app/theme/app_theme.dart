import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_radius.dart';

class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.signalOrange,
      brightness: Brightness.light,
      surface: AppColors.paper,
    ).copyWith(
      primary: AppColors.graphite,
      onPrimary: AppColors.warmWhite,
      secondary: AppColors.signalOrange,
      onSecondary: Colors.white,
      error: AppColors.closedRed,
      onError: Colors.white,
      surface: AppColors.paper,
      onSurface: AppColors.graphite,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.warmWhite,
      textTheme: _textTheme(colorScheme.onSurface),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.graphite,
      ),
      cardTheme: CardThemeData(
        color: AppColors.panel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: const BorderSide(color: AppColors.concrete),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.concrete),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.concrete),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.signalOrange, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.signalOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceCool,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        labelStyle: _textTheme(colorScheme.onSurface).labelMedium!,
      ),
    );
  }

  static ThemeData dark() {
    final base = light();
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.signalOrange,
      brightness: Brightness.dark,
      surface: const Color(0xFF1B2027),
    ).copyWith(
      primary: AppColors.warmWhite,
      onPrimary: AppColors.graphite,
      secondary: AppColors.signalOrange,
      onSecondary: Colors.white,
      error: AppColors.closedRed,
      onError: Colors.white,
      surface: const Color(0xFF1B2027),
      onSurface: AppColors.warmWhite,
    );

    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkScaffold,
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      textTheme: _textTheme(AppColors.warmWhite),
      appBarTheme: base.appBarTheme.copyWith(
        foregroundColor: AppColors.warmWhite,
      ),
      colorScheme: colorScheme,
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: AppColors.darkSurface,
      ),
    );
  }

  static TextTheme _textTheme(Color color) {
    return TextTheme(
      displaySmall: TextStyle(
        fontFamily: 'sans-serif-condensed',
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'sans-serif-condensed',
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.3,
      ),
      titleLarge: TextStyle(
        fontFamily: 'sans-serif-condensed',
        fontWeight: FontWeight.w700,
        color: color,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'sans-serif',
        color: color,
        height: 1.4,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'sans-serif',
        color: color,
        height: 1.35,
      ),
      labelLarge: TextStyle(
        fontFamily: 'sans-serif',
        fontWeight: FontWeight.w700,
        color: color,
      ),
      labelMedium: TextStyle(
        fontFamily: 'sans-serif',
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}
