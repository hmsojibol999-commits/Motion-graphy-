import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database_provider.dart';
import 'category_repository.dart';
import 'reminder_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(databaseProvider).categoryDao);
});

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepository(ref.watch(databaseProvider).reminderDao);
});
