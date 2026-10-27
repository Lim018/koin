import 'package:flutter/material.dart';

import 'app_colors.dart';

ThemeData buildAppTheme() {
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.sage,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.sage,
        onPrimary: Colors.white,
        secondary: AppColors.sunset,
        onSecondary: Colors.white,
        surface: AppColors.card,
        onSurface: AppColors.textPrimary,
        error: AppColors.sunset,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.canvas,
    // Bundled in assets/fonts (SIL OFL, see Inter-OFL.txt).
    fontFamily: 'Inter',
    // Inter is bundled (assets/fonts, SIL OFL) so text renders offline.
    // Hierarchy: headlineLarge for money totals, headlineMedium for page
    // titles, titleMedium for card titles, bodySmall/labelMedium for labels.
    textTheme:
        const TextTheme(
              headlineLarge: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1.15,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              headlineMedium: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
              displaySmall: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              titleLarge: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            )
            .apply(
              bodyColor: AppColors.textPrimary,
              displayColor: AppColors.textPrimary,
            )
            .copyWith(
              // apply() recolours every style; supporting labels stay muted.
              bodySmall: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              labelMedium: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: AppColors.textSecondary,
              ),
            ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: AppColors.sageSoft,
      linearTrackColor: AppColors.track,
      linearMinHeight: 8,
      borderRadius: BorderRadius.circular(99),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.track,
      thickness: 1,
      space: 1,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.card,
      selectedColor: AppColors.sageLight,
      side: const BorderSide(color: AppColors.chipBorder),
      shape: const StadiumBorder(),
      labelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textOnChip,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.sage,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
  );
}
