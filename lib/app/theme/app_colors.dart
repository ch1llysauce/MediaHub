import 'package:flutter/material.dart';

/// Centralized semantic color tokens for MediaHub as specified in docs/UI_DESIGN.md
abstract class AppColors {
  // Dark Theme Palette
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
  static const Color darkPrimary = Color(0xFF00E5FF); // Vibrant Cyan
  static const Color darkSecondary = Color(0xFF651FFF); // Deep Indigo
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0BEC5);

  // Light Theme Palette
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF0F4F8);
  static const Color lightPrimary = Color(0xFF02569B); // Deep Blue
  static const Color lightSecondary = Color(0xFF00B0FF);
  static const Color lightTextPrimary = Color(0xFF111111);
  static const Color lightTextSecondary = Color(0xFF666666);

  // Status & Utility Colors
  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFD600);
}
