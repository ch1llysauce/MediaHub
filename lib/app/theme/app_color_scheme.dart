import 'package:flutter/material.dart';

/// Available accent color schemes for MediaHub customization, sorted by color spectrum family.
enum AppColorScheme {
  red('Scarlet Red', Color(0xFFFF1744), Color(0xFFD50000)),
  rose('Crimson Rose', Color(0xFFFF4081), Color(0xFFC2185B)),
  purple('Neon Violet', Color(0xFFD500F9), Color(0xFF6A1B9A)),
  blue('Deep Sapphire', Color(0xFF29B6F6), Color(0xFF0277BD)),
  teal('Electric Teal', Color(0xFF00E5FF), Color(0xFF00838F)),
  green('Emerald Mint', Color(0xFF00E676), Color(0xFF2E7D32)),
  gold('Electric Gold', Color(0xFFFFD600), Color(0xFFF57F17)),
  orange('Sunset Amber', Color(0xFFFF9100), Color(0xFFE65100)),
  slate('Platinum Slate', Color(0xFFECEFF1), Color(0xFF37474F));

  final String displayName;
  final Color darkPrimary;
  final Color lightPrimary;

  const AppColorScheme(
    this.displayName,
    this.darkPrimary,
    this.lightPrimary,
  );
}
