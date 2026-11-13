import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_enums.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/scheduler/alarm_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/reminder_card.dart';
import '../editor/editor_screen.dart';
import 'home_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final tab = ref.watch(homeTabProvider);
    final async = ref.watch(filteredRemindersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('RemindMe')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  ref.read(homeSearchProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: 'Search reminders',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          ref.read(homeSearchProvider.notifier).state = '';
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
          ),
          _TabBar(
            selected: tab,
            onChanged: (t) => ref.read(homeTabProvider.notifier).state = t,
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: async.when(
              data: (list) => list.isEmpty
                  ? _emptyFor(tab)
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final r = list[i];
                        return ReminderCard(
                          reminder: r,
                          onTap: () => _openEditor(context, r),
                          onToggleDone: () async {
                            final svc = ref.read(alarmServiceProvider);
                            if (r.status == ReminderStatus.completed) {
                              await svc.save(r.copyWith(status: ReminderStatus.active));
                            } else {
                              await svc.complete(r);
                            }
                          },
                        ).animate(delay: (i * 20).ms).fadeIn(duration: 200.ms).slideY(begin: 0.05, end: 0);
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, null),
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, ReminderEntity? r) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditorScreen(existing: r)));
  }

  Widget _emptyFor(HomeTab tab) {
    final m = {
      HomeTab.today: ('Nothing today', 'Tap + to add one.'),
      HomeTab.upcoming: ('Nothing upcoming', 'Future reminders appear here.'),
      HomeTab.completed: ('No completed', 'Finished reminders appear here.'),
      HomeTab.missed: ('No missed', 'You are all caught up.'),
      HomeTab.all: ('No reminders yet', 'Tap + to create your first.'),
    };
    final info = m[tab]!;
    return EmptyState(icon: Icons.event_note, title: info.$1, body: info.$2);
  }
}

class _TabBar extends StatelessWidget {
  final HomeTab selected;
  final ValueChanged<HomeTab> onChanged;
  const _TabBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: HomeTab.values.map((t) => Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xs),
          child: ChoiceChip(
            selected: t == selected,
            label: Text(_lbl(t)),
            onSelected: (_) => onChanged(t),
          ),
        )).toList(),
      ),
    );
  }
  String _lbl(HomeTab t) => switch (t) {
        HomeTab.today => 'Today', HomeTab.upcoming => 'Upcoming',
        HomeTab.completed => 'Done', HomeTab.missed => 'Missed', HomeTab.all => 'All',
      };
}
