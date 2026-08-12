import 'package:flutter/material.dart';

/// Visual tokens for the network simulator debug UI.
abstract final class NetworkSimulatorTheme {
  static const background = Color(0xFF0B1220);
  static const surface = Color(0xFF111827);
  static const surfaceHigh = Color(0xFF1A2332);
  static const accent = Color(0xFF22D3EE);
  static const accentSoft = Color(0xFF67E8F9);
  static const textPrimary = Color(0xFFF8FAFC);
  static const textMuted = Color(0xFF94A3B8);
  static const error = Color(0xFFF87171);
  static const success = Color(0xFF34D399);

  static ThemeData dark() {
    const seed = accent;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
        surface: surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: background,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(color: textMuted),
        bodySmall: TextStyle(color: textMuted, height: 1.4),
        labelLarge: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
