import '../../core/constants/app_enums.dart';
import '../../domain/entities/reminder.dart';
import '../db/daos/reminder_dao.dart';
import '../db/database.dart';

class ReminderRepository {
  final ReminderDao _dao;
  ReminderRepository(this._dao);

  Stream<List<ReminderEntity>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(ReminderEntity.fromRow).toList());

  Stream<List<ReminderEntity>> watchByStatus(ReminderStatus status) => _dao
      .watchByStatus(status.index)
      .map((rows) => rows.map(ReminderEntity.fromRow).toList());

  Stream<List<ReminderEntity>> watchBetween(DateTime from, DateTime to) =>
      _dao
          .watchBetween(from.millisecondsSinceEpoch, to.millisecondsSinceEpoch)
          .map((rows) => rows.map(ReminderEntity.fromRow).toList());

  Future<List<ReminderEntity>> getActiveForReschedule() async =>
      (await _dao.getActiveForReschedule())
          .map(ReminderEntity.fromRow)
          .toList();

  Future<ReminderEntity?> getById(String id) async {
    final row = await _dao.getById(id);
    return row == null ? null : ReminderEntity.fromRow(row);
  }

  Future<void> upsert(ReminderEntity r) => _dao.upsertOne(r.toCompanion());

  Future<void> delete(String id) => _dao.deleteById(id);

  Future<List<ReminderEntity>> search(String q) async =>
      (await _dao.search(q)).map(ReminderEntity.fromRow).toList();

  Future<void> purgeTrashOlderThan(Duration age) => _dao.purgeTrashOlderThan(
        DateTime.now().subtract(age).millisecondsSinceEpoch,
      );
}
