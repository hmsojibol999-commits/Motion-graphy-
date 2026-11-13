import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_enums.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/date_utils.dart';
import '../data/repositories/repositories.dart';
import '../domain/entities/category.dart';
import '../domain/entities/reminder.dart';
import '../features/settings/settings_providers.dart';
import 'press_scale.dart';

class ReminderCard extends ConsumerWidget {
  final ReminderEntity reminder;
  final VoidCallback? onTap;
  final VoidCallback? onToggleDone;
  const ReminderCard({
    super.key,
    required this.reminder,
    this.onTap,
    this.onToggleDone,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final locale = ref.watch(settingsProvider).locale.languageCode;

    final isDone = reminder.status == ReminderStatus.completed;
    final isOverdue = reminder.isOverdue;
    final isPinned = reminder.pinned;

    return PressScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xxs,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: t.colorScheme.surface,
          borderRadius: AppRadii.allMd,
          border: Border.all(
            color: isOverdue
                ? AppColors.danger.withOpacity(0.4)
                : t.colorScheme.outlineVariant,
            width: 0.8,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CheckButton(done: isDone, onTap: onToggleDone),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isPinned)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(Icons.push_pin,
                              size: 14, color: t.colorScheme.primary),
                        ),
                      Expanded(
                        child: Text(
                          reminder.title.isEmpty
                              ? '(No title)'
                              : reminder.title,
                          style: t.textTheme.titleSmall?.copyWith(
                            decoration:
                                isDone ? TextDecoration.lineThrough : null,
                            color: isDone
                                ? t.colorScheme.onSurfaceVariant
                                : t.colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (reminder.priority != Priority.none)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(
                            color: reminder.priority.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: isOverdue
                            ? AppColors.danger
                            : t.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          DateX.humanDateTime(reminder.occurrenceAt,
                              locale: locale),
                          style: t.textTheme.bodySmall?.copyWith(
                            color: isOverdue
                                ? AppColors.danger
                                : t.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (reminder.repeatType != RepeatType.once)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.repeat,
                            size: 12,
                            color: t.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  if (reminder.categoryId != null)
                    _CategoryChip(categoryId: reminder.categoryId!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  final bool done;
  final VoidCallback? onTap;
  const _CheckButton({required this.done, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.curve,
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? AppColors.success : Colors.transparent,
            border: Border.all(
              color: done ? AppColors.success : t.colorScheme.outline,
              width: 1.6,
            ),
          ),
          child: done
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

class _CategoryChip extends ConsumerWidget {
  final String categoryId;
  const _CategoryChip({required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final cats = ref.watch(_categoryByIdProvider(categoryId));
    return cats.when(
      data: (c) {
        if (c == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _parseHex(c.colorHex),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                c.name,
                style: t.textTheme.labelSmall
                    ?.copyWith(color: t.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

final _categoryByIdProvider =
    FutureProvider.family<CategoryEntity?, String>((ref, id) async {
  return ref.watch(categoryRepositoryProvider).getById(id);
});

Color _parseHex(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}
