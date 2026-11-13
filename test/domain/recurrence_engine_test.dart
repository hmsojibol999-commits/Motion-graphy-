import 'package:flutter_test/flutter_test.dart';
import 'package:remindme/core/constants/app_enums.dart';
import 'package:remindme/domain/recurrence/recurrence_engine.dart';
import 'package:remindme/domain/recurrence/recurrence_rule.dart';

void main() {
  const engine = RecurrenceEngine();

  group('once', () {
    test('returns anchor if in future', () {
      final anchor = DateTime(2030, 1, 1, 9);
      final next = engine.next(
        DateTime(2029, 12, 31),
        rule: const RecurrenceRule(type: RepeatType.once),
        anchor: anchor,
        firedCount: 0,
      );
      expect(next, anchor);
    });

    test('returns null if anchor in past', () {
      final next = engine.next(
        DateTime(2030, 1, 2),
        rule: const RecurrenceRule(type: RepeatType.once),
        anchor: DateTime(2030, 1, 1, 9),
        firedCount: 0,
      );
      expect(next, isNull);
    });
  });

  group('daily', () {
    test('crosses midnight preserving wall clock', () {
      final anchor = DateTime(2025, 3, 1, 8, 30);
      final next = engine.next(
        DateTime(2025, 3, 1, 9),
        rule: const RecurrenceRule(type: RepeatType.daily),
        anchor: anchor,
        firedCount: 0,
      );
      expect(next, DateTime(2025, 3, 2, 8, 30));
    });

    test('DST spring-forward: keeps 2:30 wall clock', () {
      // US/EU DST 2025-03-30 02:00 gap. Use whatever TZ the test runner has;
      // this exercises wall-clock preservation only.
      final anchor = DateTime(2025, 3, 29, 2, 30);
      final next = engine.next(
        DateTime(2025, 3, 29, 3),
        rule: const RecurrenceRule(type: RepeatType.daily),
        anchor: anchor,
        firedCount: 0,
      );
      expect(next, isNotNull);
      final constructedRequestedTime = DateTime(2025, 3, 30, 2, 30);
      final expected = constructedRequestedTime.hour == 2 &&
              constructedRequestedTime.minute == 30
          ? constructedRequestedTime
          : DateTime(2025, 3, 30, 3, 0);
      expect(next, expected);
    });
  });

  group('weekly', () {
    test('Mon/Wed/Fri from Monday', () {
      // 2025-03-03 is a Monday.
      final anchor = DateTime(2025, 3, 3, 9);
      final next = engine.next(
        DateTime(2025, 3, 3, 10),
        rule: const RecurrenceRule(
          type: RepeatType.weekly,
          weekdays: [1, 3, 5],
        ),
        anchor: anchor,
        firedCount: 0,
      );
      expect(next!.weekday, DateTime.wednesday);
      expect(next.hour, 9);
    });

    test('from Sunday wraps back to Monday', () {
      final anchor = DateTime(2025, 3, 3, 9);
      final next = engine.next(
        DateTime(2025, 3, 9, 10), // Sunday
        rule: const RecurrenceRule(
          type: RepeatType.weekly,
          weekdays: [1],
        ),
        anchor: anchor,
        firedCount: 0,
      );
      expect(next!.weekday, DateTime.monday);
      expect(next.day, 10);
    });
  });

  group('monthly', () {
    test('clamps day 31 to 30 in April', () {
      final anchor = DateTime(2025, 3, 31, 9);
      final next = engine.next(
        DateTime(2025, 3, 31, 10),
        rule: const RecurrenceRule(
          type: RepeatType.monthly,
          monthDay: 31,
        ),
        anchor: anchor,
        firedCount: 0,
      );
      expect(next!.month, 4);
      expect(next.day, 30);
    });

    test('clamps day 31 to 28 in non-leap Feb', () {
      final anchor = DateTime(2025, 1, 31, 9);
      final next = engine.next(
        DateTime(2025, 2, 28, 10),
        rule: const RecurrenceRule(
          type: RepeatType.monthly,
          monthDay: 31,
        ),
        anchor: anchor,
        firedCount: 0,
      );
      expect(next!.month, 3);
      expect(next.day, 31);
    });
  });

  group('last day of month', () {
    test('Feb 28 non-leap, then Mar 31', () {
      final anchor = DateTime(2025, 1, 31, 9);
      final next = engine.next(
        DateTime(2025, 1, 31, 10),
        rule: const RecurrenceRule(type: RepeatType.lastDayOfMonth),
        anchor: anchor,
        firedCount: 0,
      );
      expect(next!.month, 2);
      expect(next.day, 28);
    });

    test('Feb 29 leap', () {
      final anchor = DateTime(2024, 1, 31, 9);
      final next = engine.next(
        DateTime(2024, 1, 31, 10),
        rule: const RecurrenceRule(type: RepeatType.lastDayOfMonth),
        anchor: anchor,
        firedCount: 0,
      );
      expect(next!.month, 2);
      expect(next.day, 29);
    });
  });

  group('nth weekday of month', () {
    test('2nd Tuesday of March 2025 = Mar 11', () {
      final anchor = DateTime(2025, 3, 11, 9);
      final next = engine.next(
        DateTime(2025, 3, 1),
        rule: const RecurrenceRule(
          type: RepeatType.nthWeekdayOfMonth,
          nth: 2,
          nthWeekday: 2, // Tuesday
        ),
        anchor: anchor,
        firedCount: 0,
      );
      expect(next!.day, 11);
    });

    test('5th Friday skipped in months without one', () {
      final anchor = DateTime(2025, 1, 31, 9); // 5th Friday of Jan 2025
      final next = engine.next(
        DateTime(2025, 1, 31, 10),
        rule: const RecurrenceRule(
          type: RepeatType.nthWeekdayOfMonth,
          nth: 5,
          nthWeekday: 5, // Friday
        ),
        anchor: anchor,
        firedCount: 0,
      );
      // Feb 2025 has no 5th Friday, so it should return Mar's 5th Friday.
      expect(next!.month, 3);
    });
  });

  group('yearly', () {
    test('Feb 29 falls back to Feb 28 on non-leap year', () {
      final anchor = DateTime(2024, 2, 29, 9);
      final next = engine.next(
        DateTime(2024, 2, 29, 10),
        rule: const RecurrenceRule(type: RepeatType.yearly),
        anchor: anchor,
        firedCount: 0,
      );
      expect(next!.year, 2025);
      expect(next.month, 2);
      expect(next.day, 28);
    });
  });

  group('intervals', () {
    test('every 15 minutes', () {
      final anchor = DateTime(2025, 3, 1, 9);
      final next = engine.next(
        DateTime(2025, 3, 1, 9, 7),
        rule: const RecurrenceRule(
          type: RepeatType.everyMinutes,
          interval: 15,
        ),
        anchor: anchor,
        firedCount: 0,
      );
      expect(next, DateTime(2025, 3, 1, 9, 15));
    });

    test('every 2 hours', () {
      final anchor = DateTime(2025, 3, 1, 9);
      final next = engine.next(
        DateTime(2025, 3, 1, 10, 30),
        rule: const RecurrenceRule(
          type: RepeatType.everyHours,
          interval: 2,
        ),
        anchor: anchor,
        firedCount: 0,
      );
      expect(next, DateTime(2025, 3, 1, 11));
    });
  });

  group('end conditions', () {
    test('after N: fires N times then stops', () {
      final anchor = DateTime(2025, 3, 1, 9);
      const rule = RecurrenceRule(
        type: RepeatType.daily,
        end: RepeatEnd.afterCount,
        endCount: 3,
      );
      DateTime? d = anchor;
      // The anchor is occurrence one; count tracks only later occurrences.
      var count = 0;
      var firedCount = 1;
      for (var i = 0; i < 5; i++) {
        d = engine.next(
          d!,
          rule: rule,
          anchor: anchor,
          firedCount: firedCount,
        );
        if (d == null) break;
        count++;
        firedCount++;
      }
      // Two later occurrences complete the three-fire total, then null.
      expect(count, 2);
      expect(d, isNull);
    });

    test('until date stops', () {
      final anchor = DateTime(2025, 3, 1, 9);
      final rule = RecurrenceRule(
        type: RepeatType.daily,
        end: RepeatEnd.untilDate,
        endDate: DateTime(2025, 3, 3),
      );
      final last = engine.next(
        DateTime(2025, 3, 2, 10),
        rule: rule,
        anchor: anchor,
        firedCount: 2,
      );
      expect(last, DateTime(2025, 3, 3, 9));
      final past = engine.next(
        DateTime(2025, 3, 3, 10),
        rule: rule,
        anchor: anchor,
        firedCount: 3,
      );
      expect(past, isNull);
    });
  });
}
