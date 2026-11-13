import '../../core/constants/app_enums.dart';

/// A pure, dependency-free description of a repeat rule.
/// All arithmetic is done in the local timezone (default: device local).
class RecurrenceRule {
  final RepeatType type;
  final int interval; // N for everyMinutes / everyHours
  final List<int> weekdays; // 1=Mon..7=Sun
  final int? monthDay; // 1..31
  final int? nth; // 1..5 (or -1 for last); used with nthWeekday
  final int? nthWeekday; // 1=Mon..7=Sun
  final RepeatEnd end;
  final DateTime? endDate;
  final int? endCount;

  const RecurrenceRule({
    required this.type,
    this.interval = 1,
    this.weekdays = const [],
    this.monthDay,
    this.nth,
    this.nthWeekday,
    this.end = RepeatEnd.never,
    this.endDate,
    this.endCount,
  });

  RecurrenceRule copyWith({
    RepeatType? type,
    int? interval,
    List<int>? weekdays,
    int? monthDay,
    int? nth,
    int? nthWeekday,
    RepeatEnd? end,
    DateTime? endDate,
    int? endCount,
  }) =>
      RecurrenceRule(
        type: type ?? this.type,
        interval: interval ?? this.interval,
        weekdays: weekdays ?? this.weekdays,
        monthDay: monthDay ?? this.monthDay,
        nth: nth ?? this.nth,
        nthWeekday: nthWeekday ?? this.nthWeekday,
        end: end ?? this.end,
        endDate: endDate ?? this.endDate,
        endCount: endCount ?? this.endCount,
      );

  /// Whether `firedCount` (number of times this reminder has already fired)
  /// has reached the configured "after N times" limit.
  bool isExhausted(int firedCount) {
    if (end == RepeatEnd.afterCount && endCount != null) {
      return firedCount >= endCount!;
    }
    return false;
  }

  /// True if `candidate` is past the until-date (date-only comparison).
  bool isPastEndDate(DateTime candidate) {
    if (end == RepeatEnd.untilDate && endDate != null) {
      final a = DateTime(candidate.year, candidate.month, candidate.day);
      final b = DateTime(endDate!.year, endDate!.month, endDate!.day);
      return a.isAfter(b);
    }
    return false;
  }
}
