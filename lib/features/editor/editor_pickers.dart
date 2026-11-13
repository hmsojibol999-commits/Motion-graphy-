import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_enums.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/repositories/repositories.dart';
import '../../domain/entities/reminder.dart';

Future<DateTime?> pickDateTime(BuildContext context, DateTime initial) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

Future<Priority?> pickPriority(BuildContext context, Priority current) {
  return showModalBottomSheet<Priority>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: Priority.values.map((p) => ListTile(
          leading: Icon(Icons.flag, color: p.color),
          title: Text(p.label),
          trailing: current == p ? const Icon(Icons.check) : null,
          onTap: () => Navigator.pop(ctx, p),
        )).toList(),
      ),
    ),
  );
}

Future<String?> pickCategory(BuildContext context, WidgetRef ref, String? current) async {
  final cats = await ref.read(categoryRepositoryProvider).getAll();
  if (!context.mounted) return null;
  return showModalBottomSheet<String?>(
    context: context,
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('None'),
            trailing: current == null ? const Icon(Icons.check) : null,
            onTap: () => Navigator.pop(ctx, null),
          ),
          ...cats.map((c) => ListTile(
            leading: CircleAvatar(
              radius: 8,
              backgroundColor: Color(int.parse('FF${c.colorHex.replaceFirst('#', '')}', radix: 16)),
            ),
            title: Text(c.name),
            trailing: current == c.id ? const Icon(Icons.check) : null,
            onTap: () => Navigator.pop(ctx, c.id),
          )),
        ],
      ),
    ),
  );
}

class RepeatResult {
  final RepeatType type;
  final int interval;
  final List<int> weekdays;
  final int? monthDay;
  final int? nth;
  final int? nthWeekday;
  final RepeatEnd end;
  final DateTime? endDate;
  final int? endCount;
  const RepeatResult({
    required this.type, required this.interval, required this.weekdays,
    required this.monthDay, required this.nth, required this.nthWeekday,
    required this.end, required this.endDate, required this.endCount,
  });
}

Future<RepeatResult?> pickRepeat(BuildContext context, ReminderEntity r) async {
  var type = r.repeatType;
  var weekdays = [...r.repeatWeekdays];
  
  final res = await showModalBottomSheet<RepeatResult>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text('Repeat', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RepeatType.values.map((x) => ChoiceChip(
                label: Text(x.label),
                selected: type == x,
                onSelected: (_) => setSt(() => type = x),
              )).toList(),
            ),
            if (type == RepeatType.weekly) ...[
              const SizedBox(height: 16),
              const Text('Days of week'),
              Wrap(
                spacing: 6,
                children: List.generate(7, (i) => FilterChip(
                  label: Text(['M','T','W','T','F','S','S'][i]),
                  selected: weekdays.contains(i+1),
                  onSelected: (sel) => setSt(() {
                    if (sel) weekdays.add(i+1); else weekdays.remove(i+1);
                  }),
                )),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, RepeatResult(
                type: type, interval: 1, weekdays: weekdays, monthDay: null,
                nth: null, nthWeekday: null, end: RepeatEnd.never,
                endDate: null, endCount: null,
              )),
              child: const Text('Save Repeat'),
            ),
          ],
        ),
      ),
    ),
  );
  return res;
}

Future<int?> pickAdvance(BuildContext context, int current) {
  const opts = {0: 'None', 5: '5 min before', 15: '15 min before', 60: '1 hr before', 1440: '1 day before'};
  return showModalBottomSheet<int>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: opts.entries.map((e) => ListTile(
          title: Text(e.value),
          trailing: current == e.key ? const Icon(Icons.check) : null,
          onTap: () => Navigator.pop(ctx, e.key),
        )).toList(),
      ),
    ),
  );
}
