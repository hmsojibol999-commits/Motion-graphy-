class AppConstants {
  AppConstants._();

  static const String appName = 'RemindMe';
  static const String dbName = 'remindme.sqlite';
  static const int dbVersion = 1;

  // Notification channels.
  static const String channelNormal = 'remindme_normal';
  static const String channelAlarm = 'remindme_alarm';
  static const String channelSnooze = 'remindme_snooze';

  // Route names.
  static const String routeHome = '/';
  static const String routeEditor = '/editor';
  static const String routeRing = '/ring';
  static const String routeOnboarding = '/onboarding';
  static const String routePermissions = '/permissions';

  // Shared prefs.
  static const String prefOnboarded = 'onboarded';
  static const String prefThemeMode = 'theme_mode';
  static const String prefLocale = 'locale';
  static const String prefFontScale = 'font_scale';
  static const String prefWeekStart = 'week_start';
  static const String prefHaptics = 'haptics_enabled';
  static const String prefDefaultSnooze = 'default_snooze_minutes';
}
