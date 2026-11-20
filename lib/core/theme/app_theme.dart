import 'package:flutter/material.dart';

abstract final class AppColors {
  static const emerald = Color(0xFF0C4A3E);
  static const emeraldLight = Color(0xFF146C5A);
  static const emeraldDark = Color(0xFF26A688);
  static const gold = Color(0xFFC59B38);
  static const goldDark = Color(0xFFE0B858);
  static const lightBg = Color(0xFFF4F6F5);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE1E7E4);
  static const darkBg = Color(0xFF0A0F0E);
  static const darkCard = Color(0xFF121A18);
  static const darkBorder = Color(0xFF22302C);
  static const success = Color(0xFF15803D);
  static const warning = Color(0xFFB45309);
  static const danger = Color(0xFFB91C1C);
  static const info = Color(0xFF1D4ED8);
}

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(primary: AppColors.emerald, secondary: AppColors.gold, surface: AppColors.lightCard, error: AppColors.danger),
        scaffoldBackgroundColor: AppColors.lightBg,
        appBarTheme: const AppBarTheme(backgroundColor: AppColors.lightCard, foregroundColor: Color(0xFF0D1B18), elevation: 0, scrolledUnderElevation: 0),
        cardTheme: CardThemeData(color: AppColors.lightCard, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: AppColors.lightBorder))),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: AppColors.lightBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.lightBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.lightBorder)),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(primary: AppColors.emeraldDark, secondary: AppColors.goldDark, surface: AppColors.darkCard, error: Color(0xFFEF4444)),
        scaffoldBackgroundColor: AppColors.darkBg,
        appBarTheme: const AppBarTheme(backgroundColor: AppColors.darkCard, foregroundColor: Color(0xFFEEF4F2), elevation: 0, scrolledUnderElevation: 0),
        cardTheme: CardThemeData(color: AppColors.darkCard, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: AppColors.darkBorder))),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: AppColors.darkBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.darkBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.darkBorder)),
        ),
      );
}
