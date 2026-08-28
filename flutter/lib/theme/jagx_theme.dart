import 'package:flutter/material.dart';

/// Grok x Claude mix: near-black field, warm sand accent, quiet chrome.
class JagxColors {
  static const bg = Color(0xFF0B0B0C);
  static const surface = Color(0xFF141416);
  static const elevated = Color(0xFF1C1C1F);
  static const fg = Color(0xFFECEAE4);
  static const muted = Color(0xFF9A9890);
  static const subtle = Color(0xFF6E6C66);
  static const accent = Color(0xFFC9B8A0);
  static const border = Color(0xFF2A2A2E);
  static const danger = Color(0xFFC45C4A);
  static const ok = Color(0xFF7D9A78);
}

class JagxTheme {
  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: JagxColors.bg,
      colorScheme: const ColorScheme.dark(
        surface: JagxColors.surface,
        primary: JagxColors.fg,
        onPrimary: JagxColors.bg,
        secondary: JagxColors.accent,
        onSecondary: JagxColors.bg,
        error: JagxColors.danger,
        outline: JagxColors.border,
      ),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: JagxColors.bg,
        foregroundColor: JagxColors.fg,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: JagxColors.surface,
        hintStyle: const TextStyle(color: JagxColors.subtle),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: JagxColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: JagxColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: JagxColors.accent, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(color: JagxColors.border, thickness: 1),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: JagxColors.elevated,
        contentTextStyle: TextStyle(color: JagxColors.fg),
      ),
    );
  }
}
