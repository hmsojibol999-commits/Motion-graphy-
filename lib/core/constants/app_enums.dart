import 'package:flutter/material.dart';

enum ReminderStatus { active, completed, snoozed, missed, archived, trashed }

enum Priority { none, low, medium, high }

extension PriorityX on Priority {
  String get label => switch (this) {
        Priority.none => 'None',
        Priority.low => 'Low',
        Priority.medium => 'Medium',
        Priority.high => 'High',
      };
  Color? get color => switch (this) {
        Priority.none => null,
        Priority.low => const Color(0xFF64748B),
        Priority.medium => const Color(0xFFD97706),
        Priority.high => const Color(0xFFDC2626),
      };
  int get weight => index;
}

enum RepeatType {
  once,
  everyMinutes,
  everyHours,
  daily,
  weekly,
  monthly,
  lastDayOfMonth,
  nthWeekdayOfMonth,
  yearly,
}

extension RepeatTypeX on RepeatType {
  String get label => switch (this) {
        RepeatType.once => 'Once',
        RepeatType.everyMinutes => 'Every N minutes',
        RepeatType.everyHours => 'Every N hours',
        RepeatType.daily => 'Daily',
        RepeatType.weekly => 'Weekly',
        RepeatType.monthly => 'Monthly',
        RepeatType.lastDayOfMonth => 'Last day of month',
        RepeatType.nthWeekdayOfMonth => 'Nth weekday of month',
        RepeatType.yearly => 'Yearly',
      };
}

enum RepeatEnd { never, untilDate, afterCount }

enum AlertType { notification, fullScreenAlarm }

enum VibrationPatternType { short, long, custom }

enum SortOption { dueAsc, dueDesc, title, priority, createdAt }
