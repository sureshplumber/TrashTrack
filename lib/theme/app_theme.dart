import 'package:flutter/material.dart';

/// Centralized Theme & Color Palette for TrashTrack (binit)
/// "High-Contrast Command" Palette
class AppColors {
  // Theme Palette Constants
  static const Color citizenBackground   = Color(0xFFF4E2CD); // Warm Cream
  static const Color officialBackground  = Color(0xFF211307); // Dark Slate Espresso
  static const Color cardDark            = Color(0xFF331D0A); // Deep Espresso
  static const Color citizenCardSurface  = Color(0xFFFAF4EC); // Soft Cream
  static const Color statusResolved      = Color(0xFF10B981); // Emerald
  static const Color statusInProgress    = Color(0xFFF59E0B); // Signal Amber
  static const Color statusUrgent        = Color(0xFFEF4444); // Crimson

  // Helper Aliases & Text/Border Tokens for High-Contrast UI
  static const Color officialCardSurface = Color(0xFF331D0A); // Deep Espresso
  static const Color urgentDanger        = Color(0xFFEF4444); // Crimson
  static const Color primaryTextLight    = Color(0xFF211307); // Dark Slate Espresso for Light Surfaces
  static const Color primaryTextDark     = Color(0xFFFAF4EC); // Soft Cream for Dark Surfaces
  static const Color secondaryTextLight  = Color(0xFF6E5D4F); // Muted Dark Brown
  static const Color secondaryTextDark   = Color(0xFFD4C3B3); // Muted Warm Cream
  static const Color borderLight         = Color(0xFFE2D2C0); // Light Sand Border
  static const Color borderDark          = Color(0xFF4A321E); // Dark Espresso Border
}

class AppTheme {
  static ThemeData get citizenTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.citizenBackground,
      primaryColor: AppColors.primaryTextLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryTextLight,
        primary: AppColors.primaryTextLight,
        surface: AppColors.citizenCardSurface,
        error: AppColors.statusUrgent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryTextLight,
        foregroundColor: AppColors.primaryTextDark,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.citizenCardSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
    );
  }

  static ThemeData get officialTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.officialBackground,
      primaryColor: AppColors.officialCardSurface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.officialCardSurface,
        primary: AppColors.officialCardSurface,
        surface: AppColors.officialCardSurface,
        error: AppColors.statusUrgent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.officialBackground,
        foregroundColor: AppColors.primaryTextDark,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.officialCardSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
    );
  }
}
