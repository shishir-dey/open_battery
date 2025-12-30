import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF1C1C1E);
  static const Color primary = Color(0xFF2962FF); // Apple Blue-ish
  static const Color success = Color(0xFF30D158); // Apple Green
  static const Color error = Color(0xFFFF453A); // Apple Red
  static const Color warning = Color(0xFFFF9F0A); // Apple Orange
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: success,
        surface: surface,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      useMaterial3: true,
      cardTheme: CardThemeData(
        // ignore: deprecated_member_use
        color: surface.withOpacity(0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    );
  }

  static TextStyle get largeValue => GoogleFonts.inter(
    fontSize: 48,
    fontWeight: FontWeight.w200,
    color: textPrimary,
  );

  static TextStyle get label => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  static TextStyle get unit => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );
}
