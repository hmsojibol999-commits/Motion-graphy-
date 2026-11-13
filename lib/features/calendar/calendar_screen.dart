import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/entities/reminder.dart';
import '../../core/constants/app_enums.dart';
import '../../widgets/reminder_card.dart';
import '../home/home_providers.dart';
import '../settings/settings_providers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(allRemindersProvider);
    final weekStart = ref.watch(settingsProvider).weekStart;

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(AppSpacing.md),
            child: TableCalendar(
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              focusedDay: _focused,
              startingDayOfWeek: weekStart == 7
                  ? StartingDayOfWeek.sunday
                  : StartingDayOfWeek.monday,
              selectedDayPredicate: (day) => isSameDay(_selected, day),
              onDaySelected: (sel, foc) {
                setState(() {
                  _selected = sel;
                  _focused = foc;
                });
              },
              onPageChanged: (foc) => _focused = foc,
              eventLoader: (day) {
                return async.value?.where((r) => isSameDay(r.occurrenceAt, day)).toList() ?? [];
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Expanded(
            child: async.when(
              data: (list) {
                final dayItems = list.where((r) =>
                    r.status != ReminderStatus.trashed &&
                    r.status != ReminderStatus.archived &&
                    isSameDay(r.occurrenceAt, _selected)).toList();
                if (dayItems.isEmpty) {
                  return const Center(child: Text('No reminders on this day'));
                }
                return ListView.builder(
                  itemCount: dayItems.length,
                  itemBuilder: (_, i) => ReminderCard(reminder: dayItems[i]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
