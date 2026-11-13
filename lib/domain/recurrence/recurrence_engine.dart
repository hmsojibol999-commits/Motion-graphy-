import '../../core/constants/app_enums.dart';
import 'recurrence_rule.dart';

/// Pure, timezone-safe next-occurrence calculator.
///
/// Contract:
///  * `from` is exclusive: the returned instant is strictly after `from`.
///  * `anchor` = the original due date; it supplies the *time of day*
///    and is the seed for intervals / weekly / monthly counting.
///  * Returned values are always in the SAME local timezone as `anchor`
///    (we never convert to UTC here - scheduling layers do that).
///  * DST-safe: the wall-clock hour/minute/second is preserved. If a local
///    time doesn't exist (spring-forward gap), the first valid instant on
///    that day is returned. If it occurs twice (fall-back), the earlier one
///    is returned.
class RecurrenceEngine {
  const RecurrenceEngine();

  /// Compute the next fire time strictly after [from].
  ///
  /// * [rule]  - the repeat rule.
  /// * [anchor] - original due date (supplies time-of-day).
  /// * [firedCount] - how many times this reminder has already fired.
  ///
  /// Returns `null` when the rule is exhausted (once / after N / past until).
  DateTime? next(
    DateTime from, {
    required RecurrenceRule rule,
    required DateTime anchor,
    required int firedCount,
  }) {
    // Once - just returns anchor if it's in the future.
    if (rule.type == RepeatType.once) {
      return anchor.isAfter(from) ? _safeWallClock(anchor) : null;
    }

    // End checks up front (cheap).
    if (rule.isExhausted(firedCount)) return null;

    final time = _timeOf(anchor); // TimeOfDay-like record
    // The first occurrence must never predate the user-selected start date,
    // even when the selected weekday/month rule matches an earlier date.
    final searchFrom = from.isBefore(anchor)
        ? anchor.subtract(const Duration(microseconds: 1))
        : from;
    DateTime? candidate = _computeNext(searchFrom, rule, anchor, time);

    // Apply end-date: if candidate is past endDate, stop.
    if (candidate != null && rule.isPastEndDate(candidate)) return null;
    return candidate;
  }

  // ---- internals -------------------------------------------------------

  DateTime? _computeNext(
    DateTime from,
    RecurrenceRule rule,
    DateTime anchor,
    _TimeOfDay time,
  ) {
    switch (rule.type) {
      case RepeatType.everyMinutes:
        return _nextEveryInterval(
          from,
          anchor,
          Duration(minutes: rule.interval.clamp(1, 100000)),
        );
      case RepeatType.everyHours:
        return _nextEveryInterval(
          from,
          anchor,
          Duration(hours: rule.interval.clamp(1, 100000)),
        );
      case RepeatType.daily:
        return _nextDaily(from, anchor, time);
      case RepeatType.weekly:
        return _nextWeekly(from, anchor, time, rule.weekdays);
      case RepeatType.monthly:
        return _nextMonthly(from, time, rule.monthDay ?? anchor.day);
      case RepeatType.lastDayOfMonth:
        return _nextLastDay(from, time);
      case RepeatType.nthWeekdayOfMonth:
        return _nextNthWeekday(
          from,
          time,
          rule.nth ?? 1,
          rule.nthWeekday ?? anchor.weekday,
        );
      case RepeatType.yearly:
        return _nextYearly(from, time, anchor.month, anchor.day);
      case RepeatType.once:
        return null; // handled by caller.
    }
  }

  DateTime _nextEveryInterval(
    DateTime from,
    DateTime anchor,
    Duration step,
  ) {
    // Fast-forward: anchor + k*step > from.
    if (anchor.isAfter(from)) return _safeWallClock(anchor);
    final diff = from.difference(anchor);
    final steps = (diff.inMicroseconds ~/ step.inMicroseconds) + 1;
    return _safeWallClock(anchor.add(step * steps));
  }

  DateTime _nextDaily(DateTime from, DateTime anchor, _TimeOfDay time) {
    var day = _dateOnly(anchor);
    if (!_dateOnly(day).isAfter(_dateOnly(from))) {
      day = _dateOnly(from);
    }
    // Build today's occurrence; if it's already past, move to tomorrow.
    var candidate = _combine(day, time);
    while (!candidate.isAfter(from)) {
      day = day.add(const Duration(days: 1));
      candidate = _combine(day, time);
    }
    // Rebuild after DST shifts: preserve wall clock.
    return _combine(day, time);
  }

  DateTime _nextWeekly(
    DateTime from,
    DateTime anchor,
    _TimeOfDay time,
    List<int> weekdays,
  ) {
    final days = weekdays.isEmpty ? [anchor.weekday] : (weekdays.toList()..sort());
    var day = _dateOnly(from);
    // scan up to 15 days - always finds a match for a non-empty set.
    for (var i = 0; i < 15; i++) {
      final candidate = _combine(day, time);
      if (days.contains(day.weekday) && candidate.isAfter(from)) {
        return _combine(day, time);
      }
      day = day.add(const Duration(days: 1));
    }
    // unreachable for non-empty weekday set.
    throw StateError('Weekly rule with no reachable weekday');
  }

  DateTime _nextMonthly(DateTime from, _TimeOfDay time, int monthDay) {
    final anchorDate = _dateOnly(from);
    final lastDay = _lastDayOf(anchorDate.year, anchorDate.month);
    final clampedDay = monthDay.clamp(1, lastDay);
    var candidate = _combine(
      DateTime(anchorDate.year, anchorDate.month, clampedDay),
      time,
    );
    if (candidate.isAfter(from)) return candidate;

    var y = anchorDate.year;
    var m = anchorDate.month + 1;
    while (true) {
      if (m > 12) {
        m = 1;
        y += 1;
      }
      final ld = _lastDayOf(y, m);
      final d = monthDay.clamp(1, ld);
      candidate = _combine(DateTime(y, m, d), time);
      if (candidate.isAfter(from)) return candidate;
      m += 1;
      if (m > 12) {
        m = 1;
        y += 1;
      }
    }
  }

  DateTime _nextLastDay(DateTime from, _TimeOfDay time) {
    var y = from.year;
    var m = from.month;
    while (true) {
      final d = _lastDayOf(y, m);
      final candidate = _combine(DateTime(y, m, d), time);
      if (candidate.isAfter(from)) return candidate;
      m += 1;
      if (m > 12) {
        m = 1;
        y += 1;
      }
    }
  }

  DateTime _nextNthWeekday(
    DateTime from,
    _TimeOfDay time,
    int nth,
    int weekday,
  ) {
    var y = from.year;
    var m = from.month;
    while (true) {
      final candidate = _nthWeekdayOf(y, m, nth, weekday, time);
      if (candidate != null && candidate.isAfter(from)) return candidate;
      m += 1;
      if (m > 12) {
        m = 1;
        y += 1;
      }
    }
  }

  DateTime _nextYearly(
    DateTime from,
    _TimeOfDay time,
    int month,
    int dayOfMonth,
  ) {
    // Handle Feb 29: fall back to Feb 28 in non-leap years.
    var y = from.year;
    while (true) {
      final lastDay = _lastDayOf(y, month);
      final d = dayOfMonth.clamp(1, lastDay);
      final candidate = _combine(DateTime(y, month, d), time);
      if (candidate.isAfter(from)) return candidate;
      y += 1;
    }
  }

  // ---- date math (timezone-safe because we work in wall-clock then
  //      build a local DateTime - Dart adjusts DST automatically) -------

  /// Build a local DateTime for the requested wall-clock time. When DST
  /// removes that time, return the first valid local minute after the gap.
  DateTime _combine(DateTime date, _TimeOfDay time) {
    final requestedMinute = time.hour * 60 + time.minute;
    // A full-day scan also handles unusual timezone changes larger than one
    // hour. Normal dates return on the first iteration.
    for (var offset = 0; offset <= 24 * 60; offset++) {
      final minuteOfDay = requestedMinute + offset;
      final dayOffset = minuteOfDay ~/ (24 * 60);
      final normalizedMinute = minuteOfDay % (24 * 60);
      final candidateDate = DateTime(
        date.year,
        date.month,
        date.day + dayOffset,
      );
      final expectedHour = normalizedMinute ~/ 60;
      final expectedMinute = normalizedMinute % 60;
      final candidate = DateTime(
        candidateDate.year,
        candidateDate.month,
        candidateDate.day,
        expectedHour,
        expectedMinute,
        time.second,
      );
      if (candidate.year == candidateDate.year &&
          candidate.month == candidateDate.month &&
          candidate.day == candidateDate.day &&
          candidate.hour == expectedHour &&
          candidate.minute == expectedMinute &&
          candidate.second == time.second) {
        return candidate;
      }
    }
    // Defensive fallback for an exotic skipped-date timezone transition.
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
      time.second,
    );
  }

  DateTime _safeWallClock(DateTime d) => d;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  int _lastDayOf(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  DateTime? _nthWeekdayOf(
    int year,
    int month,
    int nth,
    int weekday,
    _TimeOfDay time,
  ) {
    if (nth > 0) {
      final first = DateTime(year, month, 1);
      var delta = (weekday - first.weekday) % 7;
      if (delta < 0) delta += 7;
      final day = 1 + delta + (nth - 1) * 7;
      final lastDay = _lastDayOf(year, month);
      if (day > lastDay) return null;
      return _combine(DateTime(year, month, day), time);
    }
    // nth < 0: last weekday of month (nth == -1).
    final lastDay = _lastDayOf(year, month);
    final last = DateTime(year, month, lastDay);
    var delta = (last.weekday - weekday) % 7;
    if (delta < 0) delta += 7;
    final day = lastDay - delta;
    return _combine(DateTime(year, month, day), time);
  }

  _TimeOfDay _timeOf(DateTime d) =>
      _TimeOfDay(d.hour, d.minute, d.second);
}

class _TimeOfDay {
  final int hour;
  final int minute;
  final int second;
  const _TimeOfDay(this.hour, this.minute, this.second);
}
