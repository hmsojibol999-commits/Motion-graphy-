import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Text styles for light and dark. Uses system fonts (Roboto / Noto Sans Bengali).
class AppTextStyles {
  AppTextStyles._();

  static TextTheme light() => _build(AppColors.lightTextPrimary,
      AppColors.lightTextSecondary, Brightness.light);
  static TextTheme dark() => _build(AppColors.darkTextPrimary,
      AppColors.darkTextSecondary, Brightness.dark);

  static TextTheme _build(Color primary, Color secondary, Brightness b) {
    return TextTheme(
      displayLarge:
          TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: primary),
      displayMedium:
          TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: primary),
      headlineLarge:
          TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: primary),
      headlineMedium:
          TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: primary),
      headlineSmall:
          TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: primary),
      titleLarge:
          TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: primary),
      titleMedium:
          TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
      titleSmall:
          TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primary),
      bodyLarge: TextStyle(fontSize: 16, height: 1.4, color: primary),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: primary),
      bodySmall: TextStyle(fontSize: 12, height: 1.35, color: secondary),
      labelLarge:
          TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primary),
      labelMedium:
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondary),
      labelSmall:
          TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: secondary),
    );
  }
}
