import 'package:flutter/material.dart';

/// "Cozy Nostalgia" palette, taken from the design in docs/standalone.html.
abstract final class AppColors {
  // Flat warm cream canvas (the default habitat's background).
  static const canvas = Color(0xFFFAF8F5);
  static const roomWall = Color(0xFFFBF1E6);

  // Surfaces.
  static const card = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFEFE9E1); // hairline on cream
  static const chipBorder = Color(0xFFE6DED3);
  static const shadow = Color(0x40503723); // rgba(80,55,35,0.25)

  // Text.
  static const textPrimary = Color(0xFF2A211B);
  static const textSecondary = Color(0xFF7A6A5E);
  static const textMuted = Color(0xFF8A7A6E);
  static const textOnChip = Color(0xFF4E4036);

  // Under budget: warm sage green.
  static const sage = Color(0xFF557A47);
  static const sageDark = Color(0xFF3F5E33);
  static const sageLight = Color(0xFFEAF1E4);
  static const sageSoft = Color(0xFF7FA06E); // dots, bars

  // Spending and over budget: soft terracotta (never harsh red).
  static const sunset = Color(0xFFD9734E);
  static const sunsetSoft = Color(0xFFE8875A); // dots, bars
  static const sunsetLight = Color(0xFFFCE6D7);
  static const sunsetInk = Color(0xFFA94F28); // text on sunsetLight

  static const track = Color(0xFFF1ECE5); // progress tracks, dividers

  // Gamification.
  static const coin = Color(0xFFEDC25E);
  static const coinDark = Color(0xFFC9962E);
}
