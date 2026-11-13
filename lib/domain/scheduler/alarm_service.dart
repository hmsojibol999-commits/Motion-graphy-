import '../../data/repositories/repositories.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_enums.dart';
import '../../data/repositories/reminder_repository.dart';
import '../entities/reminder.dart';
import '../recurrence/recurrence_engine.dart';
import '../recurrence/recurrence_rule.dart';
import 'native_actions_channel.dart';
import 'scheduler_providers.dart';

/// Glue between DB, RecurrenceEngine and platform Scheduler.
class AlarmService {
  final ReminderRepository _repo;
  final Ref _ref;
  final NativeActionsChannel _actions = NativeActionsChannel();
  final RecurrenceEngine _engine = const RecurrenceEngine();

  AlarmService(this._ref, this._repo);

  /// Save (create or update) a reminder: persist then (re)schedule.
  Future<ReminderEntity> save(ReminderEntity r) async {
    final now = DateTime.now();
    var updated = r.copyWith(updatedAt: now);

    // Compute nextFireAt so UI shows correct value.
    if (r.repeatType == RepeatType.once) {
      updated = updated.copyWith(nextFireAt: updated.dueAt);
    } else {
      final next = _engine.next(
        now.subtract(const Duration(seconds: 1)),
        rule: _ruleOf(updated),
        anchor: updated.dueAt,
        firedCount: updated.firedCount,
      );
      updated = updated.copyWith(
        nextFireAt: next,
        status: next == null ? ReminderStatus.completed : updated.status,
        completedAt: next == null ? now : updated.completedAt,
      );
    }

    await _repo.upsert(updated);
    await _ref.read(schedulerServiceProvider).schedule(updated);
    return updated;
  }

  /// Mark as completed and cancel its notifications.
  Future<void> complete(ReminderEntity r) async {
    final now = DateTime.now();
    final updated = r.copyWith(
      status: ReminderStatus.completed,
      completedAt: now,
      updatedAt: now,
      nextFireAt: null,
    );
    await _ref.read(schedulerServiceProvider).cancel(r);
    await _repo.upsert(updated);
  }

  /// Snooze - schedule a temporary reminder [minutes] from now.
  Future<void> snooze(ReminderEntity r, int minutes) async {
    if (r.currentSnoozeCount >= r.maxSnoozeCount) return;
    final now = DateTime.now();
    final at = now.add(Duration(minutes: minutes));
    final nextRegular = r.repeatType == RepeatType.once
        ? at
        : _engine.next(
            now,
            rule: _ruleOf(r),
            anchor: r.dueAt,
            firedCount: r.firedCount + 1,
          );
    final updated = r.copyWith(
      status: ReminderStatus.snoozed,
      snoozedUntil: at,
      nextFireAt: nextRegular,
      currentSnoozeCount: r.currentSnoozeCount + 1,
      firedCount: r.repeatType == RepeatType.once
          ? r.firedCount
          : r.firedCount + 1,
      updatedAt: DateTime.now(),
    );
    await _repo.upsert(updated);
    await _ref.read(schedulerServiceProvider).schedule(updated);
  }

  /// After a fire, compute & arm the next occurrence. Called by app when
  /// it opens and finds pending actions or a fired reminder.
  Future<void> advanceAfterFire(ReminderEntity r) async {
    if (r.repeatType == RepeatType.once) {
      await complete(r);
      return;
    }
    final next = _engine.next(
      DateTime.now(),
      rule: _ruleOf(r),
      anchor: r.dueAt,
      firedCount: r.firedCount + 1,
    );
    final updated = r.copyWith(
      firedCount: r.firedCount + 1,
      currentSnoozeCount: 0,
      nextFireAt: next,
      status: next == null ? ReminderStatus.completed : ReminderStatus.active,
      updatedAt: DateTime.now(),
      completedAt: next == null ? DateTime.now() : null,
    );
    await _repo.upsert(updated);
    if (next != null) {
      await _ref.read(schedulerServiceProvider).schedule(updated);
    } else {
      await _ref.read(schedulerServiceProvider).cancel(r);
    }
  }

  /// Delete a reminder and cancel everything it scheduled.
  Future<void> delete(ReminderEntity r) async {
    await _ref.read(schedulerServiceProvider).cancel(r);
    await _repo.delete(r.id);
  }

  /// Re-arm everything after: cold start, boot, TZ change, permission grant.
  Future<void> rescheduleAll() async {
    final list = await _repo.getActiveForReschedule();
    final now = DateTime.now();
    for (final r in list) {
      // A missed one-shot should not remain active with no pending alarm.
      if (r.nextFireAt != null &&
          r.nextFireAt!.isBefore(now) &&
          r.repeatType == RepeatType.once) {
        await _repo.upsert(
          r.copyWith(status: ReminderStatus.missed, updatedAt: now),
        );
        continue;
      }
      // For repeating reminders, retain a pending snooze separately while
      // recomputing the next regular occurrence from the original anchor.
      var candidate = r;
      if (r.status == ReminderStatus.snoozed &&
          r.snoozedUntil != null &&
          !r.snoozedUntil!.isAfter(now)) {
        candidate = r.copyWith(
          status: ReminderStatus.active,
          snoozedUntil: null,
        );
      }
      if (candidate.repeatType != RepeatType.once) {
        final next = _engine.next(
          now.subtract(const Duration(seconds: 1)),
          rule: _ruleOf(candidate),
          anchor: candidate.dueAt,
          firedCount: candidate.firedCount,
        );
        if (next != null) {
          final updated = candidate.copyWith(nextFireAt: next);
          await _repo.upsert(updated);
          await _ref.read(schedulerServiceProvider).schedule(updated);
        } else if (candidate.status == ReminderStatus.snoozed &&
            candidate.snoozedUntil != null &&
            candidate.snoozedUntil!.isAfter(now)) {
          final updated = candidate.copyWith(
            nextFireAt: null,
            updatedAt: now,
          );
          await _repo.upsert(updated);
          await _ref.read(schedulerServiceProvider).schedule(updated);
        } else {
          await _repo.upsert(candidate.copyWith(
            status: ReminderStatus.completed,
            nextFireAt: null,
            completedAt: now,
            updatedAt: now,
          ));
        }
      } else {
        await _repo.upsert(candidate);
        await _ref.read(schedulerServiceProvider).schedule(candidate);
      }
    }
  }

  /// Consume queued native actions (Done/Snooze/Skip done while app closed).
  Future<void> consumeNativeActions() async {
    final actions = await _actions.consumePending();
    if (actions.isEmpty) return;
    for (final a in actions) {
      final type = a['type'] as String?;
      final id = a['id'] as String?;
      if (id == null) continue;
      final r = await _repo.getById(id);
      if (r == null) continue;
      switch (type) {
        case 'fired':
          final now = DateTime.now();
          if (r.repeatType == RepeatType.once) {
            await _repo.upsert(r.copyWith(
              status: ReminderStatus.missed,
              nextFireAt: null,
              updatedAt: now,
            ));
          } else {
            final firedCount = (a['firedCount'] as num?)?.toInt() ??
                r.firedCount + 1;
            final nextMs = (a['nextFireAtMs'] as num?)?.toInt();
            final hasNext = a['hasNext'] == true && nextMs != null;
            await _repo.upsert(r.copyWith(
              firedCount: firedCount > r.firedCount ? firedCount : r.firedCount,
              currentSnoozeCount: 0,
              nextFireAt: hasNext
                  ? DateTime.fromMillisecondsSinceEpoch(nextMs)
                  : null,
              status: hasNext ? ReminderStatus.active : ReminderStatus.completed,
              completedAt: hasNext ? null : now,
              updatedAt: now,
            ));
          }
          break;
        case 'done':
          await complete(r);
          break;
        case 'snooze':
          if (r.currentSnoozeCount >= r.maxSnoozeCount) break;
          final untilMs = (a['untilMs'] as num?)?.toInt();
          if (untilMs != null) {
            final at = DateTime.fromMillisecondsSinceEpoch(untilMs);
            final nextRegular = r.repeatType == RepeatType.once
                ? at
                : (r.nextFireAt ?? _engine.next(
                    DateTime.now(),
                    rule: _ruleOf(r),
                    anchor: r.dueAt,
                    firedCount: r.firedCount,
                  ));
            final updated = r.copyWith(
              status: ReminderStatus.snoozed,
              snoozedUntil: at,
              nextFireAt: nextRegular,
              currentSnoozeCount: r.currentSnoozeCount + 1,
              updatedAt: DateTime.now(),
            );
            await _repo.upsert(updated);
            await _ref.read(schedulerServiceProvider).schedule(updated);
          }
          break;
        case 'skip':
          if (a['isSnooze'] == true) {
            if (r.repeatType == RepeatType.once || r.nextFireAt == null) {
              await complete(r);
            } else {
              final updated = r.copyWith(
                status: ReminderStatus.active,
                snoozedUntil: null,
                // The main repeat occurrence was already armed when the
                // previous occurrence fired. Its snooze budget starts fresh.
                currentSnoozeCount: 0,
                updatedAt: DateTime.now(),
              );
              await _repo.upsert(updated);
              await _ref.read(schedulerServiceProvider).schedule(updated);
            }
          }
          // A normal occurrence is already advanced natively and recorded by
          // the preceding "fired" action. Advancing again would skip a cycle.
          break;
      }
    }
  }

  RecurrenceRule _ruleOf(ReminderEntity r) => RecurrenceRule(
        type: r.repeatType,
        interval: r.repeatInterval,
        weekdays: r.repeatWeekdays,
        monthDay: r.repeatMonthDay,
        nth: r.repeatNth,
        nthWeekday: r.repeatNthWeekday,
        end: r.repeatEndType,
        endDate: r.repeatEndDate,
        endCount: r.repeatEndCount,
      );
}

final alarmServiceProvider = Provider<AlarmService>((ref) {
  return AlarmService(ref, ref.watch(reminderRepositoryProvider));
});
