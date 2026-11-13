import 'package:drift/drift.dart';

import '../../data/db/database.dart';
import '../../domain/entities/category.dart';
import '../db/daos/category_dao.dart';

class CategoryRepository {
  final CategoryDao _dao;
  CategoryRepository(this._dao);

  Stream<List<CategoryEntity>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(CategoryEntity.fromRow).toList());

  Future<List<CategoryEntity>> getAll() async =>
      (await _dao.getAll()).map(CategoryEntity.fromRow).toList();

  Future<CategoryEntity?> getById(String id) async {
    final row = await _dao.getById(id);
    return row == null ? null : CategoryEntity.fromRow(row);
  }

  Future<void> upsert(CategoryEntity c) => _dao.upsertOne(c.toCompanion());

  Future<void> delete(String id) => _dao.deleteById(id);

  Future<void> create({
    required String id,
    required String name,
    required String colorHex,
    required String iconName,
    int sortOrder = 0,
  }) async {
    final now = DateTime.now();
    await _dao.upsertOne(CategoriesCompanion.insert(
      id: id,
      name: name,
      colorHex: Value(colorHex),
      iconName: Value(iconName),
      sortOrder: Value(sortOrder),
      createdAt: now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    ));
  }
}
