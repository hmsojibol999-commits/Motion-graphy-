import 'package:flutter_test/flutter_test.dart';
import 'package:remindme/core/constants/app_enums.dart';
import 'package:remindme/domain/entities/attachment.dart';
import 'package:remindme/domain/entities/category.dart';
import 'package:remindme/domain/entities/checklist_item.dart';
import 'package:remindme/domain/entities/reminder.dart';

void main() {
  group('backup serialization', () {
    test('reminder round trip retains alert, recurrence and child data', () {
      final created = DateTime(2026, 1, 2, 3, 4);
      final reminder = ReminderEntity(
        id: 'reminder-1',
        title: 'Medicine',
        note: 'After breakfast',
        dueAt: DateTime(2026, 1, 3, 8, 30),
        categoryId: 'health',
        priority: Priority.high,
        repeatType: RepeatType.weekly,
        repeatWeekdays: const [1, 3, 5],
        repeatEndType: RepeatEnd.afterCount,
        repeatEndCount: 12,
        alertType: AlertType.fullScreenAlarm,
        snoozeMinutes: 5,
        maxSnoozeCount: 3,
        checklist: const [
          ChecklistItem(id: 'task-1', text: 'Take with water', done: true),
        ],
        attachments: const [
          Attachment(path: '/local/voice.m4a', name: 'voice.m4a', kind: 'audio'),
        ],
        createdAt: created,
        updatedAt: created,
      );

      final restored = ReminderEntity.fromJson(reminder.toJson());
      expect(restored.id, reminder.id);
      expect(restored.dueAt, reminder.dueAt);
      expect(restored.priority, Priority.high);
      expect(restored.repeatType, RepeatType.weekly);
      expect(restored.repeatWeekdays, [1, 3, 5]);
      expect(restored.repeatEndType, RepeatEnd.afterCount);
      expect(restored.repeatEndCount, 12);
      expect(restored.alertType, AlertType.fullScreenAlarm);
      expect(restored.checklist.single.done, isTrue);
      expect(restored.attachments.single.path, '/local/voice.m4a');
    });

    test('category round trip keeps visual metadata and ordering', () {
      final created = DateTime(2026, 2, 3, 4, 5);
      final category = CategoryEntity(
        id: 'work',
        name: 'Work',
        colorHex: '#4F46E5',
        iconName: 'work',
        sortOrder: 2,
        isArchived: true,
        createdAt: created,
        updatedAt: created,
      );

      final restored = CategoryEntity.fromJson(category.toJson());
      expect(restored.id, category.id);
      expect(restored.name, category.name);
      expect(restored.colorHex, category.colorHex);
      expect(restored.sortOrder, 2);
      expect(restored.isArchived, isTrue);
    });
  });
}
