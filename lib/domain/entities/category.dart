import 'package:drift/drift.dart';

import '../../data/db/database.dart';

class CategoryEntity {
  final String id;
  final String name;
  final String colorHex;
  final String iconName;
  final int sortOrder;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.iconName,
    required this.sortOrder,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  CategoryEntity copyWith({
    String? name,
    String? colorHex,
    String? iconName,
    int? sortOrder,
    bool? isArchived,
    DateTime? updatedAt,
  }) =>
      CategoryEntity(
        id: id,
        name: name ?? this.name,
        colorHex: colorHex ?? this.colorHex,
        iconName: iconName ?? this.iconName,
        sortOrder: sortOrder ?? this.sortOrder,
        isArchived: isArchived ?? this.isArchived,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory CategoryEntity.fromRow(Category r) => CategoryEntity(
        id: r.id,
        name: r.name,
        colorHex: r.colorHex,
        iconName: r.iconName,
        sortOrder: r.sortOrder,
        isArchived: r.isArchived,
        createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt),
      );


  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorHex': colorHex,
        'iconName': iconName,
        'sortOrder': sortOrder,
        'isArchived': isArchived,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  factory CategoryEntity.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    DateTime date(Object? value) => value is num
        ? DateTime.fromMillisecondsSinceEpoch(value.toInt())
        : DateTime.tryParse(value?.toString() ?? '') ?? now;
    return CategoryEntity(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      colorHex: json['colorHex'] as String? ?? '#6366F1',
      iconName: json['iconName'] as String? ?? 'folder',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isArchived: json['isArchived'] as bool? ?? false,
      createdAt: date(json['createdAt']),
      updatedAt: date(json['updatedAt']),
    );
  }

  CategoriesCompanion toCompanion() => CategoriesCompanion(
        id: Value(id),
        name: Value(name),
        colorHex: Value(colorHex),
        iconName: Value(iconName),
        sortOrder: Value(sortOrder),
        isArchived: Value(isArchived),
        createdAt: Value(createdAt.millisecondsSinceEpoch),
        updatedAt: Value(updatedAt.millisecondsSinceEpoch),
      );
}
