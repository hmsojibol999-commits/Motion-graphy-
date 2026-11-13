import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_enums.dart';
import '../../data/repositories/repositories.dart';
import '../../domain/entities/reminder.dart';

enum HomeTab { today, upcoming, completed, missed, all }

final homeTabProvider = StateProvider<HomeTab>((ref) => HomeTab.today);

final homeSearchProvider = StateProvider<String>((ref) => '');

final allRemindersProvider = StreamProvider<List<ReminderEntity>>((ref) {
  return ref.watch(reminderRepositoryProvider).watchAll();
});

final filteredRemindersProvider =
    Provider<AsyncValue<List<ReminderEntity>>>((ref) {
  final all = ref.watch(allRemindersProvider);
  final tab = ref.watch(homeTabProvider);
  final query = ref.watch(homeSearchProvider).trim().toLowerCase();

  return all.whenData((list) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    Iterable<ReminderEntity> filtered = list.where((r) {
      if (r.status == ReminderStatus.trashed) return false;
      if (r.status == ReminderStatus.archived) return false;
      return true;
    });

    filtered = switch (tab) {
      HomeTab.today => filtered.where((r) =>
          (r.status == ReminderStatus.active ||
              r.status == ReminderStatus.snoozed) &&
          r.occurrenceAt.isBefore(todayEnd)),
      HomeTab.upcoming => filtered.where((r) =>
          (r.status == ReminderStatus.active ||
              r.status == ReminderStatus.snoozed) &&
          !r.occurrenceAt.isBefore(todayEnd)),
      HomeTab.completed =>
        filtered.where((r) => r.status == ReminderStatus.completed),
      HomeTab.missed =>
        filtered.where((r) => r.status == ReminderStatus.missed),
      HomeTab.all => filtered,
    };

    if (query.isNotEmpty) {
      filtered = filtered.where((r) =>
          r.title.toLowerCase().contains(query) ||
          r.note.toLowerCase().contains(query));
    }

    final result = filtered.toList()
      ..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return a.occurrenceAt.compareTo(b.occurrenceAt);
      });
    return result;
  });
});
