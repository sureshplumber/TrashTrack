import 'package:flutter/material.dart';

/// Centralized Theme & Color Palette for TrashTrack (binit)
/// Option 3: "High-Contrast Command" (Civic Teal Palette)
class AppColors {
  // Palette Roles & Surfaces
  static const Color citizenBackground = Color(0xFFF2F7F4);
  static const Color citizenCardSurface = Color(0xFFFFFFFF);
  static const Color officialBackground = Color(0xFF0F2E24);
  static const Color officialCardSurface = Color(0xFF173A2C);

  // Status & Priority Indicators
  static const Color statusResolved = Color(0xFF1D9E75);
  static const Color statusInProgress = Color(0xFFE0A527);
  static const Color urgentDanger = Color(0xFFD1495B);

  // Primary Text & Icons
  static const Color primaryTextLight = Color(0xFF0F2E24); // For light backgrounds
  static const Color primaryTextDark = Color(0xFFF2F7F4);  // For dark backgrounds
  static const Color secondaryTextLight = Color(0xFF4A6056);
  static const Color secondaryTextDark = Color(0xFFA3B8AE);

  // Border & Divider Colors
  static const Color borderLight = Color(0xFFD0E0D8);
  static const Color borderDark = Color(0xFF24503E);
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
        error: AppColors.urgentDanger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryTextLight,
        foregroundColor: AppColors.primaryTextDark,
        elevation: 0,
      ),
      cardTheme: CardTheme(
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
        error: AppColors.urgentDanger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.officialBackground,
        foregroundColor: AppColors.primaryTextDark,
        elevation: 0,
      ),
      cardTheme: CardTheme(
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
