import 'package:flutter_test/flutter_test.dart';
import 'package:remindme/core/constants/app_enums.dart';
import 'package:remindme/domain/entities/reminder.dart';
import 'package:remindme/domain/recurrence/occurrence_helper.dart';

ReminderEntity _mk({
  required DateTime dueAt,
  RepeatType type = RepeatType.daily,
  int fired = 0,
}) =>
    ReminderEntity(
      id: 'x',
      title: 't',
      note: '',
      dueAt: dueAt,
      repeatType: type,
      firedCount: fired,
      createdAt: dueAt,
      updatedAt: dueAt,
    );

void main() {
  test('upcoming daily returns 5 consecutive days', () {
    final r = _mk(dueAt: DateTime(2025, 3, 1, 9));
    final list = OccurrenceHelper.upcoming(r, DateTime(2025, 2, 28));
    expect(list.length, 5);
    expect(list.first, DateTime(2025, 3, 1, 9));
    expect(list.last, DateTime(2025, 3, 5, 9));
  });

  test('upcoming once returns just dueAt', () {
    final r = _mk(
      dueAt: DateTime(2025, 3, 1, 9),
      type: RepeatType.once,
    );
    final list = OccurrenceHelper.upcoming(r, DateTime(2025, 2, 28));
    expect(list, [DateTime(2025, 3, 1, 9)]);
  });

  test('upcoming skips past dueAt when fired > 0', () {
    final r = _mk(
      dueAt: DateTime(2025, 3, 1, 9),
      type: RepeatType.daily,
      fired: 2,
    );
    final list = OccurrenceHelper.upcoming(r, DateTime(2025, 3, 2));
    expect(list.first, DateTime(2025, 3, 3, 9));
  });
}
