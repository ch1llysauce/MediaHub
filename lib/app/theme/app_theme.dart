import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_color_scheme.dart';

/// Centralized Material 3 ThemeData generator for MediaHub
abstract class AppTheme {
  static ThemeData getDarkTheme([AppColorScheme scheme = AppColorScheme.teal]) {
    final primaryColor = scheme.darkPrimary;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: AppColors.darkSecondary,
        surface: AppColors.darkSurface,
        surfaceContainerHigh: AppColors.darkSurfaceVariant,
        onSurface: AppColors.darkTextPrimary,
        onSurfaceVariant: AppColors.darkTextSecondary,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: AppColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedIconTheme: IconThemeData(color: primaryColor),
        selectedLabelTextStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        unselectedIconTheme: const IconThemeData(color: AppColors.darkTextSecondary),
        unselectedLabelTextStyle: const TextStyle(color: AppColors.darkTextSecondary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ThemeData getLightTheme([AppColorScheme scheme = AppColorScheme.teal]) {
    final primaryColor = scheme.lightPrimary;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: AppColors.lightSecondary,
        surface: AppColors.lightSurface,
        surfaceContainerHigh: AppColors.lightSurfaceVariant,
        onSurface: AppColors.lightTextPrimary,
        onSurfaceVariant: AppColors.lightTextSecondary,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextPrimary,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: AppColors.lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedIconTheme: IconThemeData(color: primaryColor),
        selectedLabelTextStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        unselectedIconTheme: const IconThemeData(color: AppColors.lightTextSecondary),
        unselectedLabelTextStyle: const TextStyle(color: AppColors.lightTextSecondary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ThemeData get darkTheme => getDarkTheme();
  static ThemeData get lightTheme => getLightTheme();
}
