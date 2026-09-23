import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF0F5C4C); // deep teal - professional POS feel
  static const primaryLight = Color(0xFF1B8A6B);
  static const accent = Color(0xFFE8A93E); // warm amber accent
  static const danger = Color(0xFFD64545);
  static const surfaceLight = Color(0xFFF6F8F7);
  static const surfaceDark = Color(0xFF10151A);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.surfaceLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Color(0xFF0B3B31),
        selectedIconTheme: IconThemeData(color: AppColors.accent),
        selectedLabelTextStyle: TextStyle(color: Colors.white),
        unselectedIconTheme: IconThemeData(color: Colors.white70),
        unselectedLabelTextStyle: TextStyle(color: Colors.white70),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primaryLight,
        secondary: AppColors.accent,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.surfaceDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0B3B31),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}
