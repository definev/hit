import 'package:flutter/material.dart';

/// Visual tokens for the hit example gallery.
abstract final class HitExampleTheme {
  static const Color ink = Color(0xFF1A1F1C);
  static const Color paper = Color(0xFFF6F3EC);
  static const Color mist = Color(0xFFE8E3D8);
  static const Color accent = Color(0xFF0F6B5C);
  static const Color accentSoft = Color(0xFFD7EFE9);
  static const Color warn = Color(0xFFB54A2E);
  static const Color warnSoft = Color(0xFFF3DDD5);
  static const Color hitFill = Color(0x330F6B5C);
  static const Color hitStroke = Color(0xFF0F6B5C);
  static const Color beforeFill = Color(0x33B54A2E);
  static const Color beforeStroke = Color(0xFFB54A2E);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.light,
        surface: paper,
      ),
      scaffoldBackgroundColor: paper,
      fontFamily: 'Georgia',
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
      appBarTheme: const AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      dividerTheme: const DividerThemeData(color: mist, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: mist,
        selectedColor: accentSoft,
        labelStyle: const TextStyle(color: ink, fontSize: 13),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
