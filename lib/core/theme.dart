import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Mirrors the Swift app's Theme.swift — a "pastel-dark" palette (muted
/// plum/navy, not flat black) with a lavender accent and a flowing script
/// font for screen titles.
class AppTheme {
  AppTheme._();

  static const Color background = Color.fromRGBO(33, 31, 46, 1);
  static const Color backgroundElevated = Color.fromRGBO(46, 43, 61, 1);
  static const Color accent = Color.fromRGBO(199, 173, 217, 1);
  static const Color textPrimary = Color.fromRGBO(237, 232, 245, 1);
  static Color get textSecondary => textPrimary.withValues(alpha: 0.6);

  static const Color bronze = Color(0xFFCD7F32);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color gold = Color(0xFFFFD700);

  /// Stand-in for the SwiftUI app's `Font.flowing` (SnellRoundhand), used for
  /// every screen's large title.
  static TextStyle flowing(double size) => GoogleFonts.dancingScript(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static ThemeData get themeData {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        surface: background,
        primary: accent,
        secondary: accent,
        error: const Color(0xFFE58C8C),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardColor: backgroundElevated,
      cardTheme: base.cardTheme.copyWith(
        color: backgroundElevated,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: backgroundElevated,
        indicatorColor: accent.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? accent : textSecondary,
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? accent : textSecondary);
        }),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: background,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? accent
              : textSecondary,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
      ),
      dividerColor: textPrimary.withValues(alpha: 0.08),
    );
  }

  static Color tierColor(String tier) {
    switch (tier) {
      case 'BRONZE':
        return bronze;
      case 'SILVER':
        return silver;
      case 'GOLD':
        return gold;
      default:
        return accent;
    }
  }
}
