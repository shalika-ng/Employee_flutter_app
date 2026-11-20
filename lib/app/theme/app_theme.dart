import 'package:flutter/material.dart';

/// Central place for colors, text styles and component themes.
class AppTheme {
  AppTheme._();

  static const Color primarySky = Color(0xFF97C1DE);
  static const Color darkSlate = Color(0xFF1E3A5F);
  static const Color scaffoldBg = Color(0xFFF7F9FF);
  static const Color dashboardBackgroundTop = Color(0xFFF0F6FA);
  static const Color dashboardBackgroundBottom = Color(0xFFDCE9F2);
  static const Color heroGradientStart = Color(0xFF2A3C50);
  static const Color heroGradientEnd = Color(0xFF1B2838);
  static const Color heroInnerCardBackground = Color(0xFF33465A);
  static const Color brandBlue = Color(0xFF345B7A);
  static const Color primaryText = Color(0xFF1E293B);
  static const Color secondaryText = Color(0xFF64748B);
  static const Color accentBlue = Color(0xFF4A90E2);
  static const Color chipBlueBackground = Color(0xFFE8F1F8);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Plus Jakarta Sans',
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

class HomeTheme {
  HomeTheme._();

  static const String fontFamily = 'Plus Jakarta Sans';

  static const Color backgroundTop = Color(0xFFDCE7F2);
  static const Color backgroundBottom = Color(0xFFCADDF0);
  static const Color heroGradientStart = Color(0xFF17466B);
  static const Color heroGradientEnd = Color(0xFF102F50);
  static const Color heroInnerCardBackground = Color(0xFF0D243C);
  static const Color primaryText = Color(0xFF102F50);
  static const Color secondaryText = Color(0xFF5B718A);
  static const Color accentBlue = Color(0xFF17466B);
  static const Color chipBlueBackground = Color(0xFFEAF3FB);
  static const Color borderBlue = Color(0xFFE2EAF4);
  static const Color icyMutedBlue = Color(0xFFADC4DC);
  static const Color lightMutedBlue = Color(0xFF8BA2BC);

  static const TextStyle pageTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: primaryText,
  );
  static const TextStyle headerTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: primaryText,
  );
  static const TextStyle headerSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: secondaryText,
  );
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15.5,
    fontWeight: FontWeight.w800,
    color: primaryText,
  );
  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.5,
    fontWeight: FontWeight.w800,
    color: primaryText,
  );
  static const TextStyle metric = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.5,
    fontWeight: FontWeight.w800,
    color: primaryText,
  );
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: primaryText,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: secondaryText,
  );
  static const TextStyle subsectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    color: primaryText,
  );
  static const TextStyle input = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.5,
    fontWeight: FontWeight.w500,
    color: primaryText,
  );
}
