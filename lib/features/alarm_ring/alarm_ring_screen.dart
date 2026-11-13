import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/scheduler/alarm_service.dart';

class AlarmRingScreen extends ConsumerStatefulWidget {
  final ReminderEntity reminder;
  const AlarmRingScreen({super.key, required this.reminder});
  @override
  ConsumerState<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends ConsumerState<AlarmRingScreen> {
  Timer? _timer;
  int _elapsed = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _elapsed++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _done() async {
    await ref.read(alarmServiceProvider).complete(widget.reminder);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _snooze() async {
    await ref.read(alarmServiceProvider).snooze(widget.reminder, widget.reminder.snoozeMinutes);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reminder;
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(Icons.alarm, size: 72, color: AppColors.accentDark),
              const SizedBox(height: AppSpacing.lg),
              Text(
                DateFormat.jm().format(DateTime.now()),
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Ringing for ${_elapsed}s',
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                r.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              if (r.note.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  r.note,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
              const Spacer(),
              if (r.checklist.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: AppRadii.allMd,
                  ),
                  child: Column(
                    children: r.checklist.map((c) => CheckboxListTile(
                      value: c.done,
                      title: Text(c.text, style: const TextStyle(color: Colors.white)),
                      onChanged: (_) {},
                    )).toList(),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.darkSurface,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      onPressed: _snooze,
                      child: Text('Snooze ${r.snoozeMinutes}m'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      onPressed: _done,
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () {
                  ref.read(alarmServiceProvider).advanceAfterFire(r);
                  Navigator.pop(context);
                },
                child: const Text('Skip', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
