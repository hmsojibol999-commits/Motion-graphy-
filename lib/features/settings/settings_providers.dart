import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';

class AppSettings {
  final ThemeMode themeMode;
  final Locale locale;
  final double fontScale;
  final int weekStart; // 1=Mon, 7=Sun
  final bool haptics;
  final int defaultSnooze;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('en'),
    this.fontScale = 1.0,
    this.weekStart = 1,
    this.haptics = true,
    this.defaultSnooze = 10,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    double? fontScale,
    int? weekStart,
    bool? haptics,
    int? defaultSnooze,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        locale: locale ?? this.locale,
        fontScale: fontScale ?? this.fontScale,
        weekStart: weekStart ?? this.weekStart,
        haptics: haptics ?? this.haptics,
        defaultSnooze: defaultSnooze ?? this.defaultSnooze,
      );
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static AppSettings _load(SharedPreferences p) {
    final themeStr = p.getString(AppConstants.prefThemeMode) ?? 'system';
    final theme = switch (themeStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final lang = p.getString(AppConstants.prefLocale) ?? 'en';
    return AppSettings(
      themeMode: theme,
      locale: Locale(lang),
      fontScale: p.getDouble(AppConstants.prefFontScale) ?? 1.0,
      weekStart: p.getInt(AppConstants.prefWeekStart) ?? 1,
      haptics: p.getBool(AppConstants.prefHaptics) ?? true,
      defaultSnooze: p.getInt(AppConstants.prefDefaultSnooze) ?? 10,
    );
  }

  Future<void> setTheme(ThemeMode m) async {
    await _prefs.setString(
      AppConstants.prefThemeMode,
      m == ThemeMode.light ? 'light' : m == ThemeMode.dark ? 'dark' : 'system',
    );
    state = state.copyWith(themeMode: m);
  }

  Future<void> setLocale(Locale l) async {
    await _prefs.setString(AppConstants.prefLocale, l.languageCode);
    state = state.copyWith(locale: l);
  }

  Future<void> setFontScale(double v) async {
    await _prefs.setDouble(AppConstants.prefFontScale, v);
    state = state.copyWith(fontScale: v);
  }

  Future<void> setWeekStart(int v) async {
    await _prefs.setInt(AppConstants.prefWeekStart, v);
    state = state.copyWith(weekStart: v);
  }

  Future<void> setHaptics(bool v) async {
    await _prefs.setBool(AppConstants.prefHaptics, v);
    state = state.copyWith(haptics: v);
  }

  Future<void> setDefaultSnooze(int v) async {
    await _prefs.setInt(AppConstants.prefDefaultSnooze, v);
    state = state.copyWith(defaultSnooze: v);
  }

}

/// Overridden in main() with an already-awaited SharedPreferences.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in main()'),
);

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(sharedPrefsProvider));
});
