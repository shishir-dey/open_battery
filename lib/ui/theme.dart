import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Apple System Colors (Dark Mode preferred base)
  static const Color background = Color(0xFF000000); // Pure Black
  static const Color surface = Color(0xFF1C1C1E); // System Gray 6 (Dark)

  // iOS System Colors
  static const Color systemBlue = Color(0xFF0A84FF);
  static const Color systemGreen = Color(0xFF30D158);
  static const Color systemRed = Color(0xFFFF453A);
  static const Color systemOrange = Color(0xFFFF9F0A);
  static const Color systemGrey = Color(0xFF8E8E93);
  static const Color systemGrey2 = Color(0xFF636366);
  static const Color systemGrey3 = Color(0xFF48484A);
  static const Color systemGrey4 = Color(0xFF3A3A3C);
  static const Color systemGrey5 = Color(0xFF2C2C2E);
  static const Color systemGrey6 = Color(0xFF1C1C1E);

  // Semantic Aliases
  static const Color primary = systemBlue;
  static const Color success = systemGreen;
  static const Color error = systemRed;
  static const Color warning = systemOrange;
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(
    0x99EBEBF5,
  ); // Label (Secondary) - 60% opacity white
  static const Color textTertiary = Color(
    0x4DEBEBF5,
  ); // Label (Tertiary) - 30% opacity white

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: success,
        surface: surface,
        error: error,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: textPrimary, displayColor: textPrimary),
      useMaterial3: true,
      cardTheme: CardThemeData(
        color: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontFamily:
              '.SF Pro Display', // Fallback to system font if Inter fails
          letterSpacing: 0.37,
        ),
      ),
    );
  }

  static TextStyle get largeTitle => GoogleFonts.inter(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: 0.37,
  );

  static TextStyle get title2 => GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: 0.35,
  );

  static TextStyle get headline => GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.41,
  );

  static TextStyle get body => GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    letterSpacing: -0.41,
  );

  static TextStyle get largeValue => GoogleFonts.inter(
    fontSize: 42,
    fontWeight: FontWeight.w300,
    color: textPrimary,
  );

  static TextStyle get label => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  static TextStyle get unit => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );
}
