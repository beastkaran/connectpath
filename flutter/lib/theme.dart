import 'package:flutter/material.dart';

class PPNColors {
  static const Color primary    = Color(0xFF1A2744); // deep navy
  static const Color accent     = Color(0xFF00C896); // emerald green
  static const Color surface    = Color(0xFFF5F7FA);
  static const Color card       = Color(0xFFFFFFFF);
  static const Color textDark   = Color(0xFF1A2744);
  static const Color textMid    = Color(0xFF5A677D);
  static const Color textLight  = Color(0xFF9BA8B9);
  static const Color danger     = Color(0xFFE53E3E);
  static const Color warning    = Color(0xFFF6AD55);
  static const Color success    = Color(0xFF48BB78);
  static const Color badge      = Color(0xFFFFD700);
}

class PPNTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    colorScheme: ColorScheme.fromSeed(
      seedColor: PPNColors.primary,
      primary: PPNColors.primary,
      secondary: PPNColors.accent,
      surface: PPNColors.surface,
    ),
    scaffoldBackgroundColor: PPNColors.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: PPNColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: PPNColors.card,
      elevation: 2,
      shadowColor: PPNColors.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: PPNColors.accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: PPNColors.textLight.withOpacity(0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: PPNColors.textLight.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PPNColors.accent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: PPNColors.accent.withOpacity(0.1),
      labelStyle: const TextStyle(color: PPNColors.accent, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
