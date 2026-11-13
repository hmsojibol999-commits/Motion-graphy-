import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Future<List<Category>> getAll() => (select(categories)
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
      .get();

  Stream<List<Category>> watchAll() => (select(categories)
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
      .watch();

  Future<Category?> getById(String id) =>
      (select(categories)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsertOne(CategoriesCompanion entry) =>
      into(categories).insertOnConflictUpdate(entry);

  Future<void> deleteById(String id) =>
      (delete(categories)..where((t) => t.id.equals(id))).go();
}
