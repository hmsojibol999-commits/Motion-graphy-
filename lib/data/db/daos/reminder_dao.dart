import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'reminder_dao.g.dart';

@DriftAccessor(tables: [Reminders])
class ReminderDao extends DatabaseAccessor<AppDatabase>
    with _$ReminderDaoMixin {
  ReminderDao(super.db);

  Stream<List<Reminder>> watchAll() => (select(reminders)
        ..orderBy([
          (t) => OrderingTerm.desc(t.pinned),
          (t) => OrderingTerm.asc(t.dueAt),
        ]))
      .watch();

  Stream<List<Reminder>> watchByStatus(int status) => (select(reminders)
        ..where((t) => t.status.equals(status))
        ..orderBy([
          (t) => OrderingTerm.desc(t.pinned),
          (t) => OrderingTerm.asc(t.dueAt),
        ]))
      .watch();

  Stream<List<Reminder>> watchBetween(int fromMs, int toMs) =>
      (select(reminders)
            ..where((t) =>
                t.dueAt.isBiggerOrEqualValue(fromMs) &
                t.dueAt.isSmallerOrEqualValue(toMs))
            ..orderBy([(t) => OrderingTerm.asc(t.dueAt)]))
          .watch();

  Future<List<Reminder>> getActiveForReschedule() => (select(reminders)
        ..where((t) =>
            t.status.isIn([0, 2]) &
            (t.nextFireAt.isNotNull() | t.snoozedUntil.isNotNull())))
      .get();

  Future<List<Reminder>> getAllActive() =>
      (select(reminders)..where((t) => t.status.equals(0))).get();

  Future<Reminder?> getById(String id) =>
      (select(reminders)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsertOne(RemindersCompanion entry) =>
      into(reminders).insertOnConflictUpdate(entry);

  Future<void> deleteById(String id) =>
      (delete(reminders)..where((t) => t.id.equals(id))).go();

  Future<void> updateStatus(String id, int status, int nowMs) =>
      (update(reminders)..where((t) => t.id.equals(id))).write(
        RemindersCompanion(
          status: Value(status),
          updatedAt: Value(nowMs),
        ),
      );

  Future<List<Reminder>> search(String q) {
    final like = '%${q.trim()}%';
    return (select(reminders)
          ..where((t) =>
              t.status.isNotValue(5) &
              (t.title.like(like) | t.note.like(like)))
          ..orderBy([(t) => OrderingTerm.asc(t.dueAt)]))
        .get();
  }

  Future<void> purgeTrashOlderThan(int cutoffMs) =>
      (delete(reminders)
            ..where((t) =>
                t.status.equals(5) & t.updatedAt.isSmallerThanValue(cutoffMs)))
          .go();
}
