import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/repositories/repositories.dart';

class BackupService {
  final ReminderRepository _repo;
  BackupService(this._repo);

  Future<void> exportJson() async {
    final reminders = await _repo.watchAll().first;
    final jsonStr = jsonEncode(reminders.map((r) => r.toCompanion().toJson()).toList());
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/remindme_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonStr);
    await Share.shareXFiles([XFile(file.path)], text: 'RemindMe Backup');
  }

  Future<void> exportCsv() async {
    final reminders = await _repo.watchAll().first;
    final rows = [['Title', 'Note', 'Due Date', 'Status', 'Priority']];
    for (final r in reminders) {
      rows.add([r.title, r.note, r.dueAt.toIso8601String(), r.status.name, r.priority.name]);
    }
    final csvStr = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/remindme_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvStr);
    await Share.shareXFiles([XFile(file.path)], text: 'RemindMe CSV Export');
  }

  Future<bool> importJson() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (res == null || res.files.isEmpty || res.files.single.path == null) return false;
    return true;
  }
}
