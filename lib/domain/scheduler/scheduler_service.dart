import '../entities/reminder.dart';

/// Returned by [SchedulerService.schedule] so the UI can surface errors
/// (e.g. exact-alarm permission missing on Android 12+).
class ScheduleResult {
  final bool ok;
  final String? errorCode;
  final String? errorMessage;
  const ScheduleResult.ok()
      : ok = true,
        errorCode = null,
        errorMessage = null;
  const ScheduleResult.error(this.errorCode, this.errorMessage) : ok = false;
}

/// Abstraction over the platform scheduler. Implementations:
///  * [AndroidScheduler]  - MethodChannel to Kotlin AlarmManager bridge.
///  * Noop fallback when running outside Android (unit tests, desktop).
abstract class SchedulerService {
  /// Schedule all notifications for [r] (advance + main). Cancels existing
  /// notifications first so there are no duplicates.
  Future<ScheduleResult> schedule(ReminderEntity r);

  /// Cancel every notification ID ever assigned to [r].
  Future<void> cancel(ReminderEntity r);

  /// Cancel by raw notification IDs (used after DB row is gone).
  Future<void> cancelByIds(List<int> ids);

  /// Nuke everything then re-arm from DB. Called after: reboot, time change,
  /// timezone change, app update, boot permission grant.
  Future<void> rescheduleAll(List<ReminderEntity> reminders);

  /// Android-specific: check + request exact-alarm permission.
  Future<bool> canScheduleExactAlarms();

  /// Android-specific: check notification permission state.
  Future<bool> hasNotificationPermission();
}
