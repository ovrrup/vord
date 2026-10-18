import 'package:flutter/material.dart';

class AppTheme {
  // Ultra-clean, distraction-free pure black OLED palette
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF000000);
  static const Color textPrimary = Color(0xFFEEEEEE);
  static const Color textSecondary = Color(0xFF7A7F8D);
  static const Color accent = Color(0xFFE2E8F0); // Understated, elegant chalk
  static const Color accentMuted = Color(0xFF2E323D);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: textPrimary,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: textPrimary,
        secondary: accent,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 72,
          fontWeight: FontWeight.w200,
          letterSpacing: -2.0,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w300,
          letterSpacing: 0.2,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.0,
          color: textSecondary,
        ),
      ),
    );
  }
}
