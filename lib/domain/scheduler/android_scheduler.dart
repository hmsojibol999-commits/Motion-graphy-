import 'dart:io';

import 'package:flutter/services.dart';

import '../entities/reminder.dart';
import 'scheduler_service.dart';

/// Bridge to native Kotlin: com.remindme.remindme/Scheduler
class AndroidScheduler implements SchedulerService {
  static const _channel = MethodChannel('com.remindme.remindme/scheduler');

  @override
  Future<ScheduleResult> schedule(ReminderEntity r) async {
    if (!Platform.isAndroid) return const ScheduleResult.ok();
    // Always cancel first to avoid duplicates.
    await cancel(r);
    final ids = _buildIds(r);
    try {
      final isSnoozedRepeat = r.status.index == 2 && r.repeatType.index != 0;
      final isSnoozedOnce = r.status.index == 2 && r.repeatType.index == 0;
      // A final repeating occurrence can still be snoozed even though it has
      // no next regular date. Never fall back to the old anchor in that case.
      if (r.status.index == 0 || isSnoozedOnce ||
          (isSnoozedRepeat && r.nextFireAt != null)) {
        await _channel.invokeMethod('schedule', {
          'reminder': _toMap(r),
          'notificationIds': ids,
        });
      }
      // Repeating reminders keep the next regular occurrence and a snooze as
      // independent alarms. One-shot snoozes use the main alarm ID.
      if (isSnoozedRepeat && r.snoozedUntil != null) {
        await _channel.invokeMethod('schedule', {
          'reminder': _toMap(r, isSnooze: true, fireAt: r.snoozedUntil),
          'notificationIds': [ids[2]],
        });
      }
      return const ScheduleResult.ok();
    } on PlatformException catch (e) {
      return ScheduleResult.error(e.code, e.message);
    }
  }

  @override
  Future<void> cancel(ReminderEntity r) => cancelByIds(_buildIds(r));

  @override
  Future<void> cancelByIds(List<int> ids) async {
    if (!Platform.isAndroid || ids.isEmpty) return;
    try {
      await _channel.invokeMethod('cancel', {'ids': ids});
    } catch (_) {/* safe to ignore */}
  }

  @override
  Future<void> rescheduleAll(List<ReminderEntity> reminders) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('cancelAll');
    } catch (_) {}
    for (final r in reminders) {
      await schedule(r);
    }
  }

  @override
  Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;
    try {
      final v = await _channel.invokeMethod<bool>('canScheduleExactAlarms');
      return v ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> hasNotificationPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final v = await _channel.invokeMethod<bool>('hasNotificationPermission');
      return v ?? false;
    } catch (_) {
      return false;
    }
  }

  // --- helpers ---

  /// Deterministic notification IDs from reminder id so we can cancel
  /// after DB row is gone. Each reminder gets a base + up to 4 children
  /// (main, advance warning, snooze re-arm, misc), with headroom below int32.
  List<int> _buildIds(ReminderEntity r) {
    final base = _hash(r.id) * 8;
    return [base, base + 1, base + 2, base + 3, base + 4];
  }

  int _hash(String s) {
    // FNV-1a in a 28-bit space; multiplying by eight below leaves room for
    // the reserved child IDs without overflowing Android's signed int.
    var h = 0x811C9DC5;
    for (final c in s.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0x0FFFFFFF;
    }
    return h == 0 ? 1 : h;
  }

  Map<String, Object?> _toMap(
    ReminderEntity r, {
    bool isSnooze = false,
    DateTime? fireAt,
  }) => {
        'id': r.id,
        'title': r.title,
        'note': r.note,
        'dueAtMs': r.dueAt.millisecondsSinceEpoch,
        'nextFireAtMs': (fireAt ?? r.nextFireAt ?? r.dueAt).millisecondsSinceEpoch,
        'currentSnoozeCount': r.currentSnoozeCount,
        'isSnooze': isSnooze || (r.status.index == 2 && r.repeatType.index == 0),
        'advanceMinutes': r.advanceMinutes,
        'alertType': r.alertType.index, // 0 notif, 1 alarm
        'soundPath': r.soundPath,
        'soundName': r.soundName,
        'vibrationType': r.vibrationType.index,
        'vibrationPattern': r.vibrationPattern,
        'flashlightBlink': r.flashlightBlink,
        'ttsRead': r.ttsRead,
        'gradualVolume': r.gradualVolume,
        'volumeLevel': r.volumeLevel,
        'ringDurationSec': r.ringDurationSec,
        'ringRepeatCount': r.ringRepeatCount,
        'snoozeMinutes': r.snoozeMinutes,
        'maxSnoozeCount': r.maxSnoozeCount,
        'dismissChallenge': r.dismissChallenge,
        'priority': r.priority.index,
        'status': r.status.index,
        'repeatType': r.repeatType.index,
        'repeatInterval': r.repeatInterval,
        'repeatWeekdays': r.repeatWeekdays,
        'repeatMonthDay': r.repeatMonthDay,
        'repeatNth': r.repeatNth,
        'repeatNthWeekday': r.repeatNthWeekday,
        'repeatEndType': r.repeatEndType.index,
        'repeatEndDateMs': r.repeatEndDate?.millisecondsSinceEpoch,
        'repeatEndCount': r.repeatEndCount,
        'firedCount': r.firedCount,
        'activeStartMin': r.activeStartMin,
        'activeEndMin': r.activeEndMin,
      };
}
