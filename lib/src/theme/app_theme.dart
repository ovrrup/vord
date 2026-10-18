import 'package:flutter/material.dart';

class AppTheme {
  // --- Dark Palette (#121212 Off-Black base) ---
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1C1F23);
  static const Color darkBorder = Color(0xFF2C3136);
  static const Color darkTextPrimary = Color(0xFFF2F4F7);
  static const Color darkTextSecondary = Color(0xFF8B949E);
  static const Color darkButton = Color(0xFF22262B);
  static const Color darkButtonPressed = Color(0xFF181B1E);

  // --- Light Palette (#FFFFFF Pure White base) ---
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF6F8FA);
  static const Color lightBorder = Color(0xFFD0D7DE);
  static const Color lightTextPrimary = Color(0xFF1F2328);
  static const Color lightTextSecondary = Color(0xFF656D76);
  static const Color lightButton = Color(0xFFF0F3F6);
  static const Color lightButtonPressed = Color(0xFFE2E6EA);

  // --- Matte Disk Progressive Stages (Dark theme) ---
  static const Color darkStage0 = Color(0xFF121212); // Off-Black
  static const Color darkStage1 = Color(0xFF1B2E24); // Deep Emerald
  static const Color darkStage2 = Color(0xFF28593D); // Muted Moss
  static const Color darkStage3 = Color(0xFF3FA36C); // Vibrant Leaf Green

  // --- Matte Disk Progressive Stages (White mode) ---
  static const Color lightStage0 = Color(0xFFFFFFFF); // Pure White
  static const Color lightStage1 = Color(0xFFF2F9F3); // Mint Tint
  static const Color lightStage2 = Color(0xFFA8D5BA); // Soft Sage
  static const Color lightStage3 = Color(0xFF2E8B57); // Pleasant Forest Green

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        surface: lightSurface,
        primary: lightTextPrimary,
        secondary: lightStage3,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 60,
          fontWeight: FontWeight.w300,
          letterSpacing: -1.5,
          color: lightTextPrimary,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: lightTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
          color: lightTextSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: lightTextSecondary,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        surface: darkSurface,
        primary: darkTextPrimary,
        secondary: darkStage3,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 60,
          fontWeight: FontWeight.w300,
          letterSpacing: -1.5,
          color: darkTextPrimary,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: darkTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
          color: darkTextSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: darkTextSecondary,
        ),
      ),
    );
  }
}
