import 'package:flutter/material.dart';

/// Single source of truth for colors.
class AppColors {
  AppColors._();

  static const Color seed = Color(0xFF4F46E5);
  static const Color accentLight = Color(0xFF4F46E5);
  static const Color accentDark = Color(0xFF818CF8);

  // Semantic (sparing use).
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);

  // Neutrals for light mode.
  static const Color lightBackground = Color(0xFFFAFAFB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F1F4);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF6B7280);

  // Neutrals for dark mode.
  static const Color darkBackground = Color(0xFF0B0B0F);
  static const Color darkSurface = Color(0xFF15161C);
  static const Color darkSurfaceVariant = Color(0xFF1E2028);
  static const Color darkBorder = Color(0xFF2A2C35);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  /// Muted category palette - use only as small dots/chips.
  static const List<Color> categoryPalette = <Color>[
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF06B6D4),
    Color(0xFF3B82F6),
    Color(0xFF64748B),
    Color(0xFF84CC16),
  ];

  static ColorScheme lightScheme() => ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
        primary: accentLight,
        surface: lightSurface,
        error: danger,
      );

  static ColorScheme darkScheme() => ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
        primary: accentDark,
        surface: darkSurface,
        error: danger,
      );
}
