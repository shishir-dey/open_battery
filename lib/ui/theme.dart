/*
 * Open Battery (Generic Chinese BMS Companion App)
 * File: lib/ui/theme.dart
 * Description: Defines the app's theme including colors, text styles, and material theme data for both light and dark UI.
 * Author: Shishir Dey
 * License: MIT
 */

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // iOS System Colors (Dark Mode)
  static const Color darkBackground = Color(0xFF000000); // Pure Black
  static const Color darkSurface = Color(0xFF1C1C1E); // System Gray 6 (Dark)
  static const Color darkSystemBlue = Color(0xFF0A84FF);
  static const Color darkSystemGreen = Color(0xFF30D158);
  static const Color darkSystemRed = Color(0xFFFF453A);
  static const Color darkSystemOrange = Color(0xFFFF9F0A);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0x99EBEBF5); // 60% opacity white
  static const Color darkTextTertiary = Color(0x4DEBEBF5); // 30% opacity white

  // iOS System Colors (Light Mode)
  static const Color lightBackground = Color(0xFFFFFFFF); // Pure White
  static const Color lightSurface = Color(0xFFF2F2F7); // System Gray 6 (Light)
  static const Color lightSystemBlue = Color(0xFF007AFF);
  static const Color lightSystemGreen = Color(0xFF34C759);
  static const Color lightSystemRed = Color(0xFFFF3B30);
  static const Color lightSystemOrange = Color(0xFFFF9500);
  static const Color lightTextPrimary = Color(0xFF000000);
  static const Color lightTextSecondary = Color(
    0x993C3C43,
  ); // 60% opacity black
  static const Color lightTextTertiary = Color(0x4D3C3C43); // 30% opacity black

  // Shared gray colors
  static const Color systemGrey = Color(0xFF8E8E93);
  static const Color systemGrey2 = Color(0xFF636366);
  static const Color systemGrey3 = Color(0xFF48484A);
  static const Color systemGrey4 = Color(0xFF3A3A3C);
  static const Color systemGrey5 = Color(0xFF2C2C2E);
  static const Color systemGrey6 = Color(0xFF1C1C1E);

  // Light gray variants
  static const Color lightSystemGrey3 = Color(0xFFC7C7CC);
  static const Color lightSystemGrey4 = Color(0xFFD1D1D6);
  static const Color lightSystemGrey5 = Color(0xFFE5E5EA);
  static const Color lightSystemGrey6 = Color(0xFFF2F2F7);

  // Legacy static colors (for backward compatibility) - prefer context-aware methods
  static const Color systemBlue = darkSystemBlue;
  static const Color systemGreen = darkSystemGreen;
  static const Color systemRed = darkSystemRed;
  static const Color systemOrange = darkSystemOrange;
  static const Color primary = systemBlue;
  static const Color success = systemGreen;
  static const Color error = systemRed;
  static const Color warning = systemOrange;
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color textTertiary = darkTextTertiary;
  static const Color background = darkBackground;
  static const Color surface = darkSurface;

  // ============== THEME DATA ==============

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: darkSystemBlue,
      colorScheme: const ColorScheme.dark(
        primary: darkSystemBlue,
        secondary: darkSystemGreen,
        surface: darkSurface,
        error: darkSystemRed,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: darkTextPrimary, displayColor: darkTextPrimary),
      useMaterial3: true,
      cardTheme: CardThemeData(
        color: darkSurface,
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
          color: darkTextPrimary,
          fontFamily: '.SF Pro Display',
          letterSpacing: 0.37,
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      primaryColor: lightSystemBlue,
      colorScheme: const ColorScheme.light(
        primary: lightSystemBlue,
        secondary: lightSystemGreen,
        surface: lightSurface,
        error: lightSystemRed,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme,
      ).apply(bodyColor: lightTextPrimary, displayColor: lightTextPrimary),
      useMaterial3: true,
      cardTheme: CardThemeData(
        color: lightSurface,
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
          color: lightTextPrimary,
          fontFamily: '.SF Pro Display',
          letterSpacing: 0.37,
        ),
      ),
    );
  }

  // ============== CONTEXT-AWARE COLORS ==============

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color getBackground(BuildContext context) {
    return isDark(context) ? darkBackground : lightBackground;
  }

  static Color getSurface(BuildContext context) {
    return isDark(context) ? darkSurface : lightSurface;
  }

  static Color getPrimary(BuildContext context) {
    return isDark(context) ? darkSystemBlue : lightSystemBlue;
  }

  static Color getSuccess(BuildContext context) {
    return isDark(context) ? darkSystemGreen : lightSystemGreen;
  }

  static Color getError(BuildContext context) {
    return isDark(context) ? darkSystemRed : lightSystemRed;
  }

  static Color getWarning(BuildContext context) {
    return isDark(context) ? darkSystemOrange : lightSystemOrange;
  }

  static Color getTextPrimary(BuildContext context) {
    return isDark(context) ? darkTextPrimary : lightTextPrimary;
  }

  static Color getTextSecondary(BuildContext context) {
    return isDark(context) ? darkTextSecondary : lightTextSecondary;
  }

  static Color getTextTertiary(BuildContext context) {
    return isDark(context) ? darkTextTertiary : lightTextTertiary;
  }

  static Color getGlassColor(BuildContext context) {
    return isDark(context) ? systemGrey6 : lightSystemGrey6;
  }

  static Color getGlassBorder(BuildContext context) {
    return isDark(context)
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);
  }

  static Color getDividerColor(BuildContext context) {
    return isDark(context) ? Colors.white10 : Colors.black12;
  }

  // ============== CONTEXT-AWARE TEXT STYLES ==============

  static TextStyle largeTitleStyle(BuildContext context) => GoogleFonts.inter(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    color: getTextPrimary(context),
    letterSpacing: 0.37,
  );

  static TextStyle title2Style(BuildContext context) => GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: getTextPrimary(context),
    letterSpacing: 0.35,
  );

  static TextStyle headlineStyle(BuildContext context) => GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: getTextPrimary(context),
    letterSpacing: -0.41,
  );

  static TextStyle bodyStyle(BuildContext context) => GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: getTextPrimary(context),
    letterSpacing: -0.41,
  );

  static TextStyle largeValueStyle(BuildContext context) => GoogleFonts.inter(
    fontSize: 42,
    fontWeight: FontWeight.w300,
    color: getTextPrimary(context),
  );

  static TextStyle labelStyle(BuildContext context) => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: getTextSecondary(context),
  );

  static TextStyle unitStyle(BuildContext context) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: getTextSecondary(context),
  );

  // ============== LEGACY STATIC TEXT STYLES (for backward compatibility) ==============
  // Note: These use hardcoded dark theme colors. Prefer context-aware methods above.

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
