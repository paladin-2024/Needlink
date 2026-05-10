import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kPrimary = Color(0xFF0891B2);
const Color kPrimaryDark = Color(0xFF0E7490);
const Color kAccent = Color(0xFFEA580C);
const Color kBackground = Color(0xFFECFEFF);
const Color kSurface = Color(0xFFFFFFFF);
const Color kForeground = Color(0xFF164E63);
const Color kDark = Color(0xFF071D2C);
const Color kMuted = Color(0xFFE8F1F6);
const Color kMutedFg = Color(0xFF64748B);
const Color kBorder = Color(0xFFE8EDF2);
const Color kUrgent = Color(0xFFEF4444);
const Color kMatched = Color(0xFF16A34A);

TextTheme _buildTextTheme() {
  final base = GoogleFonts.plusJakartaSansTextTheme();
  return base.copyWith(
    displayLarge: GoogleFonts.sora(fontWeight: FontWeight.bold, color: kForeground),
    displayMedium: GoogleFonts.sora(fontWeight: FontWeight.bold, color: kForeground),
    headlineLarge: GoogleFonts.sora(fontWeight: FontWeight.bold, color: kForeground),
    headlineMedium: GoogleFonts.sora(fontWeight: FontWeight.bold, color: kForeground),
    headlineSmall: GoogleFonts.sora(fontWeight: FontWeight.w700, color: kForeground),
    titleLarge: GoogleFonts.sora(fontWeight: FontWeight.w600, color: kForeground),
    titleMedium: GoogleFonts.sora(fontWeight: FontWeight.w600, color: kForeground, fontSize: 15),
    bodyLarge: GoogleFonts.plusJakartaSans(color: kForeground, fontSize: 15),
    bodyMedium: GoogleFonts.plusJakartaSans(color: kMutedFg, fontSize: 13),
    labelSmall: GoogleFonts.jetBrainsMono(fontSize: 10, color: kMutedFg),
    labelMedium: GoogleFonts.jetBrainsMono(fontSize: 12, color: kMutedFg),
  );
}

final ThemeData needLinkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: kPrimary,
    onPrimary: Colors.white,
    secondary: kAccent,
    onSecondary: Colors.white,
    error: Color(0xFFDC2626),
    onError: Colors.white,
    surface: kSurface,
    onSurface: kForeground,
  ),
  scaffoldBackgroundColor: kBackground,
  fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
  textTheme: _buildTextTheme(),
  appBarTheme: AppBarTheme(
    backgroundColor: kSurface,
    foregroundColor: kForeground,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    centerTitle: false,
    titleTextStyle: GoogleFonts.sora(
      fontWeight: FontWeight.bold,
      fontSize: 18,
      color: kForeground,
    ),
  ),
  cardTheme: CardThemeData(
    color: kSurface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: kBorder),
    ),
    margin: EdgeInsets.zero,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF8FAFB),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: kBorder, width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: kBorder, width: 2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: kPrimary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFFB0BECA), fontSize: 15),
    labelStyle: GoogleFonts.plusJakartaSans(color: kMutedFg, fontSize: 13, fontWeight: FontWeight.w600),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      minimumSize: const Size(double.infinity, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: kPrimary),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: kMuted,
    labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: kMutedFg),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    side: const BorderSide(color: kBorder),
  ),
  dividerTheme: const DividerThemeData(color: kBorder, space: 0),
);
