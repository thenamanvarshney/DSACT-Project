import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kinetic Toybox (AutoMatik Theme) Palette & Design Tokens
class AppColors {
  AppColors._();

  // ── Brand & Core Accents ──
  static const Color primary = Color(0xFF6C5CE7); // Electric Indigo
  static const Color accentSecondary = Color(0xFF70A6FF); // Electric Cyan
  static const Color accentWarm = Color(0xFFFFAAA6); // Pastel Melon
  static const Color accentLime = Color(0xFF00E676); // Neon Lime trace glow

  // ── Functional & Feedback ──
  static const Color successBase = Color(0xFF10B981); // Emerald
  static const Color successSubtle = Color(0xFFECFDF5); // Mint background
  static const Color errorBase = Color(0xFFFF6B6B); // Coral / Error
  static const Color errorSubtle = Color(0xFFFEF2F2);
  static const Color warningBase = Color(0xFFFFD166);

  // ── Canvas & Surfaces ──
  static const Color canvasBg = Color(0xFFFAF9F6); // Warm off-white
  static const Color gridDot = Color(0xFFE2E8F0); // Pastel dot matrix
  static const Color surfaceCard = Color(0xFFFFFFFF); // Pure white claymorphic card
  static const Color surfaceContainerLow = Color(0xFFF4F3F1); // Inset ribbon surface
  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color surfaceGlass = Color(0xEEFFFFFF);

  // ── Neutral Typography & Ink ──
  static const Color textPrimary = Color(0xFF1E1B4B); // Deep Navy Ink
  static const Color textSecondary = Color(0xFF64748B); // Slate
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // ── Legacy Aliases for seamless compatibility ──
  static const Color scaffoldDark = canvasBg;
  static const Color surfaceDark = surfaceContainerLow;
  static const Color cardDark = surfaceCard;
  static const Color canvasDark = canvasBg;
  static const Color accentPurple = primary;
  static const Color accentBlue = accentSecondary;
  static const Color accentCyan = accentSecondary;
  static const Color accentCoral = errorBase;
  static const Color accentAmber = warningBase;
  static const Color stateDefault = Color(0xFFEDE9FE);
  static const Color stateSelected = primary;
  static const Color stateInitial = primary;
  static const Color stateFinal = successBase;
  static const Color stateActive = accentLime;
  static const Color accepted = successBase;
  static const Color rejected = errorBase;

  // ── Gradients ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient indigoGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF8A2387)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successSurface = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient acceptedGradient = successSurface;

  static const LinearGradient rejectedGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFE94057)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient canvasGradient = LinearGradient(
    colors: [Color(0xFFFAF9F6), Color(0xFFF5F4F0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

/// App-wide Kinetic Toybox Theme Data
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.canvasBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accentSecondary,
        surface: AppColors.surfaceCard,
        error: AppColors.errorBase,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      textTheme: ThemeData.light().textTheme.apply(fontFamily: GoogleFonts.plusJakartaSans().fontFamily).copyWith(
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 0.2,
        ),
        labelMedium: GoogleFonts.jetBrainsMono(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.primary.withAlpha(80),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 20),
    );
  }

  // Alias for darkTheme to keep backward compatibility
  static ThemeData get darkTheme => lightTheme;
}
