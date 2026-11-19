import 'package:flutter/material.dart';

/// Central place for colors, text styles and component themes.
class AppTheme {
  AppTheme._();

  // Brand UI Colors
  static const Color primarySky = Color(0xFF97C1DE);
  static const Color darkSlate = Color(0xFF1E3A5F);
  static const Color scaffoldBg = Color(0xFFF7F9FF);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Plus Jakarta Sans', // Requires font registration in pubspec.yaml
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySky,
        primary: darkSlate,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.white, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.white, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: primarySky, width: 1.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkSlate,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}