import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remindme/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/timezone_helper.dart';
import 'domain/scheduler/alarm_service.dart';
import 'domain/scheduler/native_actions_channel.dart';
import 'features/settings/settings_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TimezoneHelper.init();
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
  );

  // Consume any actions that happened while the app was closed
  try {
    final alarmService = container.read(alarmServiceProvider);
    await alarmService.consumeNativeActions();
    await alarmService.rescheduleAll();
  } catch (_) {}

  runApp(UncontrolledProviderScope(
    container: container,
    child: const ReminderApp(),
  ));
}

class ReminderApp extends ConsumerStatefulWidget {
  const ReminderApp({super.key});

  @override
  ConsumerState<ReminderApp> createState() => _ReminderAppState();
}

class _ReminderAppState extends ConsumerState<ReminderApp>
    with WidgetsBindingObserver {
  bool _syncingNativeActions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NativeActionsChannel().setPendingListener(_syncNativeActions);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncNativeActions();
  }

  Future<void> _syncNativeActions() async {
    if (_syncingNativeActions) return;
    _syncingNativeActions = true;
    try {
      final alarms = ref.read(alarmServiceProvider);
      await alarms.consumeNativeActions();
      await alarms.rescheduleAll();
    } catch (_) {
      // Native alarm delivery must not prevent the app UI from opening.
    } finally {
      _syncingNativeActions = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'RemindMe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      locale: settings.locale,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(
              mq.textScaler.scale(1.0) * settings.fontScale,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('bn')],
      routerConfig: router,
    );
  }
}
