import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/repositories/repositories.dart';
import '../backup/backup_service.dart';
import 'settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final t = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SectionHeader('Appearance'),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Theme'),
            subtitle: Text(settings.themeMode.name.toUpperCase()),
            onTap: () {
              final next = settings.themeMode == ThemeMode.system
                  ? ThemeMode.light
                  : settings.themeMode == ThemeMode.light
                      ? ThemeMode.dark
                      : ThemeMode.system;
              notifier.setTheme(next);
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: Text(settings.locale.languageCode == 'bn' ? 'বাংলা' : 'English'),
            onTap: () {
              final next = settings.locale.languageCode == 'bn'
                  ? const Locale('en')
                  : const Locale('bn');
              notifier.setLocale(next);
            },
          ),
          const Divider(),
          _SectionHeader('Behavior'),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: const Text('Haptics'),
            value: settings.haptics,
            onChanged: notifier.setHaptics,
          ),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Text size'),
            subtitle: Text('${(settings.fontScale * 100).round()}%'),
            trailing: SizedBox(
              width: 140,
              child: Slider(
                value: settings.fontScale.clamp(0.85, 1.30).toDouble(),
                min: 0.85,
                max: 1.30,
                divisions: 9,
                label: '${(settings.fontScale * 100).round()}%',
                onChanged: notifier.setFontScale,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_view_week),
            title: const Text('Week starts on'),
            subtitle: Text(settings.weekStart == 7 ? 'Sunday' : 'Monday'),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Monday'),
                        onTap: () {
                          notifier.setWeekStart(1);
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: const Text('Sunday'),
                        onTap: () {
                          notifier.setWeekStart(7);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.snooze),
            title: const Text('Default snooze'),
            subtitle: Text('${settings.defaultSnooze} minutes'),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [5, 10, 15, 30, 60].map((m) => ListTile(
                      title: Text('$m minutes'),
                      onTap: () {
                        notifier.setDefaultSnooze(m);
                        Navigator.pop(context);
                      },
                    )).toList(),
                  ),
                ),
              );
            },
          ),
          const Divider(),
          _SectionHeader('Data'),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Export Backup (JSON)'),
            onTap: () => BackupService(ref.read(reminderRepositoryProvider), ref.read(categoryRepositoryProvider)).exportJson(),
          ),
          ListTile(
            leading: const Icon(Icons.table_chart),
            title: const Text('Export as CSV'),
            onTap: () => BackupService(ref.read(reminderRepositoryProvider), ref.read(categoryRepositoryProvider)).exportCsv(),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Import Backup (JSON)'),
            subtitle: const Text('Restore reminders from a RemindMe backup'),
            onTap: () async {
              try {
                final imported = await BackupService(
                  ref.read(reminderRepositoryProvider),
                  ref.read(categoryRepositoryProvider),
                ).importJson();
                if (!context.mounted || !imported) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Backup imported.')),
                );
              } catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Import failed: $error')),
                );
              }
            },
          ),
          const Divider(),
          _SectionHeader('Security'),
          const ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('App PIN / biometric lock'),
            subtitle: Text('Not available in this build. Your device lock still protects the phone itself.'),
          ),
          const ListTile(
            leading: Icon(Icons.volume_off_outlined),
            title: Text('UI click sounds'),
            subtitle: Text('Not available in this build.'),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'RemindMe v1.0.0\nAll data stays on device.',
              textAlign: TextAlign.center,
              style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xs),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
