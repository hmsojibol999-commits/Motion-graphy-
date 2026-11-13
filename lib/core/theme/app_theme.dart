import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(
        scheme: AppColors.lightScheme(),
        textTheme: AppTextStyles.light(),
        scaffold: AppColors.lightBackground,
        surfaceVariant: AppColors.lightSurfaceVariant,
        border: AppColors.lightBorder,
        brightness: Brightness.light,
      );

  static ThemeData get dark => _build(
        scheme: AppColors.darkScheme(),
        textTheme: AppTextStyles.dark(),
        scaffold: AppColors.darkBackground,
        surfaceVariant: AppColors.darkSurfaceVariant,
        border: AppColors.darkBorder,
        brightness: Brightness.dark,
      );

  static ThemeData _build({
    required ColorScheme scheme,
    required TextTheme textTheme,
    required Color scaffold,
    required Color surfaceVariant,
    required Color border,
    required Brightness brightness,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      textTheme: textTheme,
      scaffoldBackgroundColor: scaffold,
      visualDensity: VisualDensity.standard,
    );
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardTheme(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.allMd,
          side: BorderSide(color: border, width: 0.8),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 0.8,
        space: AppSpacing.md,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surfaceVariant,
        side: BorderSide.none,
        labelStyle: textTheme.labelLarge,
        shape: const StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadii.allSm,
          borderSide: BorderSide(color: border, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.allSm,
          borderSide: BorderSide(color: border, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.allSm,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.allSm),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.allSm),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.allSm),
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: border, width: 0.8),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.allMd),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        modalBackgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
        ),
        showDragHandle: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scaffold,
        indicatorColor: scheme.primary.withOpacity(0.12),
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
        height: 64,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.allSm),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xxs,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.allSm),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}
