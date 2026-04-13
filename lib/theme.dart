import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color bg          = Color(0xFF0A0A0F);
  static const Color surface     = Color(0xFF13131A);
  static const Color card        = Color(0xFF1C1C27);
  static const Color border      = Color(0xFF2A2A3A);
  static const Color accent      = Color(0xFF6C63FF);
  static const Color accentGlow  = Color(0x446C63FF);
  static const Color accentLight = Color(0xFF9D97FF);
  static const Color green       = Color(0xFF22C55E);
  static const Color amber       = Color(0xFFF59E0B);
  static const Color red         = Color(0xFFEF4444);
  static const Color textPrimary   = Color(0xFFEEEEF4);
  static const Color textSecondary = Color(0xFF8888AA);
  static const Color textMuted     = Color(0xFF44445A);
  static const Color videoColor   = Color(0xFF6C63FF);
  static const Color audioColor   = Color(0xFF22C55E);
  static const Color trimColor    = Color(0xFFF59E0B);
  static const Color convertColor = Color(0xFF06B6D4);
  static const Color splitColor   = Color(0xFFEC4899);

  static TextTheme get textTheme => TextTheme(
    displayLarge: GoogleFonts.syne(fontSize: 36, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -1),
    displayMedium: GoogleFonts.syne(fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.5),
    headlineMedium: GoogleFonts.syne(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary),
    headlineSmall: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
    titleLarge: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
    titleMedium: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary),
    bodyLarge: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary),
    bodyMedium: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w400, color: textSecondary),
    bodySmall: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w400, color: textMuted),
    labelLarge: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: 0.5),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      secondary: green,
      surface: surface,
      error: red,
    ),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
      iconTheme: const IconThemeData(color: textPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        elevation: 0,
      ),
    ),
    dividerColor: border,
    cardColor: card,
  );
}