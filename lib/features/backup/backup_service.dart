import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/repositories/reminder_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/category.dart';

class BackupService {
  final ReminderRepository _repo;
  final CategoryRepository _categories;
  BackupService(this._repo, this._categories);

  Future<void> exportJson() async {
    final reminders = await _repo.watchAll().first;
    final categories = await _categories.getAll();
    final payload = {
      'format': 'remindme-backup',
      'schemaVersion': 2,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'reminders': reminders.map((r) => r.toJson()).toList(),
    };
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/remindme_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(payload), flush: true);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
      text: 'RemindMe Backup',
    ));
  }

  Future<void> exportCsv() async {
    final reminders = await _repo.watchAll().first;
    final rows = <List<dynamic>>[
      ['ID', 'Title', 'Note', 'Due Date', 'Status', 'Priority', 'Created At', 'Updated At'],
    ];
    for (final r in reminders) {
      rows.add([
        r.id,
        r.title,
        r.note,
        r.dueAt.toIso8601String(),
        r.status.name,
        r.priority.name,
        r.createdAt.toIso8601String(),
        r.updatedAt.toIso8601String(),
      ]);
    }
    final csvStr = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/remindme_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvStr, flush: true);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
      text: 'RemindMe CSV Export',
    ));
  }

  /// Import is validated completely before any row is written, avoiding a
  /// half-import when a backup is malformed.
  Future<bool> importJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return false;

    final file = result.files.single;
    final String contents;
    if (file.bytes != null) {
      contents = utf8.decode(file.bytes!, allowMalformed: false);
    } else if (file.path != null) {
      contents = await File(file.path!).readAsString();
    } else {
      throw const FormatException('The selected backup could not be read.');
    }

    final decoded = jsonDecode(contents);
    final List<dynamic> records;
    final List<dynamic> categoryRecords;
    if (decoded is Map<String, dynamic> &&
        decoded['format'] == 'remindme-backup' &&
        (decoded['schemaVersion'] == 1 || decoded['schemaVersion'] == 2) &&
        decoded['reminders'] is List) {
      records = decoded['reminders'] as List<dynamic>;
      categoryRecords = decoded['categories'] is List
          ? decoded['categories'] as List<dynamic>
          : const <dynamic>[];
    } else if (decoded is List) {
      // Accept a plain list of entity JSON objects from early local exports.
      records = decoded;
      categoryRecords = const <dynamic>[];
    } else {
      throw const FormatException('This is not a supported RemindMe backup.');
    }

    final parsedCategories = <CategoryEntity>[];
    for (final record in categoryRecords) {
      if (record is! Map) {
        throw const FormatException('The backup contains an invalid category.');
      }
      parsedCategories.add(
        CategoryEntity.fromJson(Map<String, dynamic>.from(record)),
      );
    }

    final parsed = <ReminderEntity>[];
    for (final record in records) {
      if (record is! Map) {
        throw const FormatException('The backup contains an invalid reminder.');
      }
      parsed.add(ReminderEntity.fromJson(Map<String, dynamic>.from(record)));
    }

    for (final category in parsedCategories) {
      await _categories.upsert(category);
    }
    for (final reminder in parsed) {
      await _repo.upsert(reminder);
    }
    return true;
  }
}
