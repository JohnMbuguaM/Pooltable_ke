import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ============ PREMIUM COLOR SYSTEM ============

  // Primary Brand - Deep Emerald Felt
  static const Color deepEmerald = Color(0xFF0B3D2E);
  static const Color deepEmeraldDark = Color(0xFF06281F);
  static const Color feltGreen = Color(0xFF0E5740);
  static const Color feltHighlight = Color(0xFF12724F);

  // Premium Gold Accents
  static const Color premiumGold = Color(0xFFD4AF37);
  static const Color goldHighlight = Color(0xFFF5D76E);
  static const Color goldDim = Color(0xFFB8941F);

  // Charcoal Foundation
  static const Color charcoalBase = Color(0xFF121212);
  static const Color charcoalElevated = Color(0xFF1A1A1A);
  static const Color charcoalCard = Color(0xFF1E1E1E);
  static const Color charcoalOverlay = Color(0xFF252525);

  // Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Legacy aliases (for backward compatibility)
  static const Color primaryGreen = deepEmerald;
  static const Color darkGreen = deepEmeraldDark;
  static const Color accentGold = premiumGold;
  static const Color accentAmber = goldHighlight;
  static const Color darkSurface = charcoalElevated;
  static const Color darkCard = charcoalCard;
  static const Color darkElevated = charcoalOverlay;

  // ============ PREMIUM TYPOGRAPHY ============

  static TextTheme _buildMonospaceTextTheme(TextTheme base) {
    return GoogleFonts.robotoMonoTextTheme(base).copyWith(
      displayLarge: GoogleFonts.robotoMono(fontSize: 57, fontWeight: FontWeight.w300, letterSpacing: -0.25),
      displayMedium: GoogleFonts.robotoMono(fontSize: 45, fontWeight: FontWeight.w300),
      displaySmall: GoogleFonts.robotoMono(fontSize: 36, fontWeight: FontWeight.w400),
      headlineLarge: GoogleFonts.robotoMono(fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      headlineMedium: GoogleFonts.robotoMono(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      headlineSmall: GoogleFonts.robotoMono(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      titleLarge: GoogleFonts.robotoMono(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 0.15),
      titleMedium: GoogleFonts.robotoMono(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.15),
      titleSmall: GoogleFonts.robotoMono(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      bodyLarge: GoogleFonts.robotoMono(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5),
      bodyMedium: GoogleFonts.robotoMono(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25),
      bodySmall: GoogleFonts.robotoMono(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4),
      labelLarge: GoogleFonts.robotoMono(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.0),
      labelMedium: GoogleFonts.robotoMono(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8),
      labelSmall: GoogleFonts.robotoMono(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.dark(
        primary: deepEmerald,
        onPrimary: Colors.white,
        secondary: premiumGold,
        onSecondary: Colors.black,
        surface: charcoalCard,
        onSurface: Colors.white,
        error: error,
        onError: Colors.white,
        tertiary: feltGreen,
        onTertiary: Colors.white,
      ),
      scaffoldBackgroundColor: charcoalBase,
      appBarTheme: AppBarTheme(
        backgroundColor: charcoalElevated,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.robotoMono(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 1.0,
        ),
      ),
      cardTheme: CardThemeData(
        color: charcoalCard,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: deepEmerald.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepEmerald,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: deepEmerald.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.robotoMono(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: premiumGold,
          side: BorderSide(color: premiumGold.withValues(alpha: 0.5), width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.robotoMono(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: premiumGold,
        foregroundColor: charcoalBase,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      textTheme: _buildMonospaceTextTheme(base.textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: charcoalOverlay,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: deepEmerald.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: deepEmerald.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: deepEmerald, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: GoogleFonts.robotoMono(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: charcoalElevated,
        selectedItemColor: premiumGold,
        unselectedItemColor: Colors.white.withValues(alpha: 0.4),
        type: BottomNavigationBarType.fixed,
        elevation: 16,
        selectedLabelStyle: GoogleFonts.robotoMono(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
        unselectedLabelStyle: GoogleFonts.robotoMono(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: charcoalCard,
        elevation: 24,
        shadowColor: Colors.black.withValues(alpha: 0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: deepEmerald.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: charcoalOverlay,
        contentTextStyle: GoogleFonts.robotoMono(
          color: Colors.white,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: deepEmerald.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),
      dividerTheme: DividerThemeData(
        color: deepEmerald.withValues(alpha: 0.2),
        thickness: 1,
      ),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.light(
        primary: deepEmerald,
        onPrimary: Colors.white,
        secondary: premiumGold,
        onSecondary: charcoalBase,
        surface: const Color(0xFFF8F8F8),
        onSurface: charcoalBase,
        error: error,
        onError: Colors.white,
        tertiary: feltGreen,
        onTertiary: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF0F0F0),
      appBarTheme: AppBarTheme(
        backgroundColor: deepEmerald,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.robotoMono(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 1.0,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: deepEmerald.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepEmerald,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.robotoMono(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: premiumGold,
        foregroundColor: charcoalBase,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      textTheme: _buildMonospaceTextTheme(base.textTheme).apply(
        bodyColor: charcoalBase,
        displayColor: charcoalBase,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: deepEmerald.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: deepEmerald.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: deepEmerald, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: GoogleFonts.robotoMono(
          color: charcoalBase.withValues(alpha: 0.4),
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: premiumGold,
        unselectedItemColor: charcoalBase.withValues(alpha: 0.4),
        type: BottomNavigationBarType.fixed,
        elevation: 16,
        selectedLabelStyle: GoogleFonts.robotoMono(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
        unselectedLabelStyle: GoogleFonts.robotoMono(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: deepEmerald.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: charcoalCard,
        contentTextStyle: GoogleFonts.robotoMono(
          color: Colors.white,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),
      dividerTheme: DividerThemeData(
        color: deepEmerald.withValues(alpha: 0.2),
        thickness: 1,
      ),
    );
  }
}
