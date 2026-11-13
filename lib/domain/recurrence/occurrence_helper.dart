import '../../core/constants/app_enums.dart';
import '../entities/reminder.dart';
import 'recurrence_engine.dart';
import 'recurrence_rule.dart';

class OccurrenceHelper {
  OccurrenceHelper._();

  static const _engine = RecurrenceEngine();

  /// Returns up to [count] upcoming occurrences strictly after [from].
  /// Includes the anchor itself if it's still in the future.
  static List<DateTime> upcoming(
    ReminderEntity r,
    DateTime from, {
    int count = 5,
  }) {
    final rule = _ruleOf(r);
    final out = <DateTime>[];

    DateTime? cursor = from;
    var fired = r.firedCount;

    // Special case: if the reminder hasn't fired yet and its dueAt is future,
    // that dueAt IS the first occurrence.
    if (fired == 0 && r.dueAt.isAfter(from)) {
      out.add(r.dueAt);
      cursor = r.dueAt;
      fired = 1;
      if (rule.type == RepeatType.once) return out;
    }

    while (out.length < count) {
      final n = _engine.next(
        cursor!,
        rule: rule,
        anchor: r.dueAt,
        firedCount: fired,
      );
      if (n == null) break;
      out.add(n);
      cursor = n;
      fired++;
      // Guard against pathological rules producing the same instant.
      if (out.length > 1 && out.last == out[out.length - 2]) break;
    }
    return out;
  }

  static RecurrenceRule _ruleOf(ReminderEntity r) => RecurrenceRule(
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
