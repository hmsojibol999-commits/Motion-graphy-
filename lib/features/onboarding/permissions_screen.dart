import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_spacing.dart';
import '../../domain/scheduler/alarm_service.dart';
import '../../domain/scheduler/scheduler_providers.dart';
import 'onboarding_provider.dart';

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('com.remindme.remindme/scheduler');

  bool _notif = false;
  bool _exact = false;
  bool _fullScreen = false;
  bool _batteryExempt = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<bool> _nativeBool(String method) async {
    if (!Platform.isAndroid) return true;
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> _check() async {
    if (!Platform.isAndroid) {
      if (mounted) setState(() => _checking = false);
      return;
    }
    final values = await Future.wait<bool>([
      ref.read(schedulerServiceProvider).hasNotificationPermission(),
      ref.read(schedulerServiceProvider).canScheduleExactAlarms(),
      _nativeBool('canUseFullScreenIntent'),
      _nativeBool('isIgnoringBatteryOptimizations'),
    ]);
    if (!mounted) return;
    setState(() {
      _notif = values[0];
      _exact = values[1];
      _fullScreen = values[2];
      _batteryExempt = values[3];
      _checking = false;
    });
  }

  Future<void> _requestNotif() async {
    await Permission.notification.request();
    await _check();
  }

  Future<void> _requestExact() async {
    if (!_exact) {
      try {
        await _channel.invokeMethod('openExactAlarmSettings');
      } on PlatformException {
        await openAppSettings();
      }
    }
    await _check();
  }

  Future<void> _requestFullScreen() async {
    if (!_fullScreen) {
      try {
        await _channel.invokeMethod('openFullScreenIntentSettings');
      } on PlatformException {
        await openAppSettings();
      }
    }
    await _check();
  }

  Future<void> _requestBatteryExemption() async {
    if (_batteryExempt) return;
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Allow reliable background alarms'),
        content: const Text(
          'Android battery controls can delay reminders. On some phones, '
          'also allow Auto-start or background activity for RemindMe and '
          'set battery use to Unrestricted. The exact menu name depends on '
          'your phone manufacturer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
    if (openSettings != true) return;
    try {
      await _channel.invokeMethod('openBatteryOptimizationSettings');
    } on PlatformException {
      await openAppSettings();
    }
    await _check();
  }

  Future<void> _finish() async {
    await ref.read(alarmServiceProvider).rescheduleAll();
    await ref.read(onboardingProvider.notifier).complete();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Permissions')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Why we need these', style: t.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'RemindMe is fully offline. These permissions are used only on '
            'this device to show alerts and help alarms run on time.',
            style: t.textTheme.bodyMedium?.copyWith(
              color: t.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _PermTile(
            title: 'Notifications',
            body: 'Shows your reminder alerts and actions.',
            granted: _notif,
            onTap: _requestNotif,
          ),
          _PermTile(
            title: 'Exact alarms',
            body: 'Lets Android fire a reminder close to the time you chose.',
            granted: _exact,
            onTap: _requestExact,
          ),
          _PermTile(
            title: 'Full-screen alarms',
            body: 'Optional. Lets alarm reminders appear over the lock screen '
                'when Android allows it.',
            granted: _fullScreen,
            onTap: _requestFullScreen,
          ),
          _PermTile(
            title: 'Battery restrictions',
            body: 'Optional. Helps prevent Android from delaying alarms. '
                'Some brands also need Auto-start enabled manually.',
            granted: _batteryExempt,
            onTap: _requestBatteryExemption,
          ),
          if (_checking)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: LinearProgressIndicator(),
            ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _finish,
            child: const Text('Get started'),
          ),
        ],
      ),
    );
  }
}

class _PermTile extends StatelessWidget {
  final String title;
  final String body;
  final bool granted;
  final VoidCallback onTap;

  const _PermTile({
    required this.title,
    required this.body,
    required this.granted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(
                granted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: granted
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.open_in_new,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
