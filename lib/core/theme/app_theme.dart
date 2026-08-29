import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Deep Ocean Matte Design System Tokens for PrawnGuard
abstract class AppColors {
  static const background = Color(0xFF0A0A0B);
  static const surfaceBase = Color(0xFF0F0F0F);
  static const surface = Color(0xFF171717);
  static const surfaceElevated = Color(0xFF222222);
  static const cardBorder = Color(0x14FFFFFF); // rgba(255,255,255,0.08)

  static const primary = Color(0xFF00E5FF); // Neon Cyan
  static const secondary = Color(0xFF10B981); // Emerald Green
  
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF9E9E9E);
  static const textTertiary = Color(0xFF616161);

  static const alertUrgent = Color(0xFFE55C5C); // Urgent / Expense Red
  static const alertWatch = Color(0xFFE5B05C); // Watch / Warning Yellow
  static const alertInfo = Color(0xFF5C9EE5); // Info Blue

  static const glassBackground = Color(0x0DFFFFFF); // rgba(255,255,255,0.05)
}

abstract class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.surface,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.alertUrgent,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        labelSmall: GoogleFonts.outfit(
          fontSize: 12,
          color: AppColors.textTertiary,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.cardBorder,
        thickness: 1,
      ),
    );
  }
}
