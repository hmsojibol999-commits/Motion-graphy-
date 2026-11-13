import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_enums.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/id_generator.dart';
import '../../domain/entities/checklist_item.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/scheduler/alarm_service.dart';
import 'editor_pickers.dart';
import 'editor_templates.dart';
import '../settings/settings_providers.dart';
import 'package:permission_handler/permission_handler.dart';

class EditorScreen extends ConsumerStatefulWidget {
  final ReminderEntity? existing;
  const EditorScreen({super.key, this.existing});
  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late ReminderEntity _draft;
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _checklistCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _draft = widget.existing ?? ReminderEntity(
      id: newId(),
      title: '',
      note: '',
      dueAt: now.add(const Duration(hours: 1)),
      snoozeMinutes: ref.read(settingsProvider).defaultSnooze,
      createdAt: now,
      updatedAt: now,
    );
    _titleCtrl.text = _draft.title;
    _noteCtrl.text = _draft.note;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    _checklistCtrl.dispose();
    super.dispose();
  }

  void _set(ReminderEntity r) {
    setState(() => _draft = r.copyWith(updatedAt: DateTime.now()));
  }


  Future<void> _applyTemplate(ReminderTemplate template) async {
    final now = DateTime.now();
    var dueAt = DateTime(now.year, now.month, now.day,
        template.hour, template.minute);
    if (!dueAt.isAfter(now)) dueAt = dueAt.add(const Duration(days: 1));
    final updated = _draft.copyWith(
      title: template.title,
      note: template.note,
      dueAt: dueAt,
      repeatType: template.once ? RepeatType.once : template.repeatType,
      repeatInterval: template.repeatInterval,
      repeatWeekdays: template.repeatWeekdays,
      repeatMonthDay: template.repeatMonthDay,
      activeStartMin: template.activeStartMin,
      activeEndMin: template.activeEndMin,
      snoozeMinutes: template.snoozeMinutes,
    );
    _titleCtrl.text = updated.title;
    _noteCtrl.text = updated.note;
    _set(updated);
  }

  Future<void> _showTemplates() async {
    final selected = await showModalBottomSheet<ReminderTemplate>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text('Quick templates',
                  style: Theme.of(sheetContext).textTheme.titleLarge),
            ),
            ...ReminderTemplate.all.map((template) => ListTile(
                  leading: const Icon(Icons.event_note),
                  title: Text(template.label),
                  subtitle: Text(template.title),
                  onTap: () => Navigator.pop(sheetContext, template),
                )),
          ],
        ),
      ),
    );
    if (selected != null && mounted) await _applyTemplate(selected);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a title')));
      return;
    }
    final toSave = _draft.copyWith(title: _titleCtrl.text.trim(), note: _noteCtrl.text.trim());
    await ref.read(alarmServiceProvider).save(toSave);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        title: Text(widget.existing == null ? 'New reminder' : 'Edit reminder'),
        actions: [
          if (widget.existing == null)
            IconButton(
              tooltip: 'Quick templates',
              onPressed: _showTemplates,
              icon: const Icon(Icons.auto_awesome_outlined),
            ),
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Title & Note
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: t.colorScheme.surface,
              borderRadius: AppRadii.allMd,
              border: Border.all(color: t.colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _titleCtrl,
                  style: t.textTheme.titleMedium,
                  decoration: const InputDecoration(hintText: 'Reminder title', border: InputBorder.none),
                  autofocus: widget.existing == null,
                ),
                const Divider(),
                TextField(
                  controller: _noteCtrl,
                  style: t.textTheme.bodyMedium,
                  decoration: const InputDecoration(hintText: 'Add a note (optional)', border: InputBorder.none),
                  maxLines: null,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Date & Time
          ListTile(
            tileColor: t.colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: AppRadii.allMd, side: BorderSide(color: t.colorScheme.outlineVariant)),
            leading: const Icon(Icons.calendar_today),
            title: Text(DateFormat.yMMMd().add_jm().format(_draft.dueAt)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final picked = await pickDateTime(context, _draft.dueAt);
              if (picked != null) _set(_draft.copyWith(dueAt: picked));
            },
          ),
          const SizedBox(height: AppSpacing.sm),

          // Repeat
          ListTile(
            tileColor: t.colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: AppRadii.allMd, side: BorderSide(color: t.colorScheme.outlineVariant)),
            leading: const Icon(Icons.repeat),
            title: Text(_draft.repeatType.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final r = await pickRepeat(context, _draft);
              if (r != null) {
                _set(_draft.copyWith(
                  repeatType: r.type, repeatInterval: r.interval,
                  repeatWeekdays: r.weekdays, repeatMonthDay: r.monthDay,
                  repeatEndType: r.end, repeatEndDate: r.endDate, repeatEndCount: r.endCount,
                ));
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),

          // Priority & Category
          Row(
            children: [
              Expanded(
                child: ListTile(
                  tileColor: t.colorScheme.surface,
                  shape: RoundedRectangleBorder(borderRadius: AppRadii.allMd, side: BorderSide(color: t.colorScheme.outlineVariant)),
                  leading: Icon(Icons.flag, color: _draft.priority.color),
                  title: Text(_draft.priority.label),
                  onTap: () async {
                    final p = await pickPriority(context, _draft.priority);
                    if (p != null) _set(_draft.copyWith(priority: p));
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ListTile(
                  tileColor: t.colorScheme.surface,
                  shape: RoundedRectangleBorder(borderRadius: AppRadii.allMd, side: BorderSide(color: t.colorScheme.outlineVariant)),
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(_draft.categoryId == null ? 'No category' : 'Category'),
                  onTap: () async {
                    final c = await pickCategory(context, ref, _draft.categoryId);
                    _set(_draft.copyWith(categoryId: c));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Advanced Settings (Progressive Disclosure)
          _AdvancedSection(draft: _draft, onChange: _set, checklistCtrl: _checklistCtrl),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: Text(widget.existing == null ? 'Create reminder' : 'Save changes'),
          ),
        ),
      ),
    );
  }
}

class _AdvancedSection extends StatelessWidget {
  final ReminderEntity draft;
  final ValueChanged<ReminderEntity> onChange;
  final TextEditingController checklistCtrl;
  const _AdvancedSection({required this.draft, required this.onChange, required this.checklistCtrl});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return ExpansionTile(
      title: const Text('Advanced Options'),
      shape: RoundedRectangleBorder(borderRadius: AppRadii.allMd, side: BorderSide(color: t.colorScheme.outlineVariant)),
      collapsedShape: RoundedRectangleBorder(borderRadius: AppRadii.allMd, side: BorderSide(color: t.colorScheme.outlineVariant)),
      backgroundColor: t.colorScheme.surface,
      collapsedBackgroundColor: t.colorScheme.surface,
      childrenPadding: const EdgeInsets.all(AppSpacing.md),
      children: [
        SwitchListTile(
          title: const Text('Full-Screen Alarm'),
          subtitle: const Text('Show on lock screen'),
          value: draft.alertType == AlertType.fullScreenAlarm,
          onChanged: (v) => onChange(draft.copyWith(alertType: v ? AlertType.fullScreenAlarm : AlertType.notification)),
        ),
        SwitchListTile(
          title: const Text('Flashlight blink'),
          value: draft.flashlightBlink,
          onChanged: (v) async {
            if (v) {
              final permission = await Permission.camera.request();
              if (!permission.isGranted) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Camera permission is needed for flashlight alerts.')),
                  );
                }
                return;
              }
            }
            onChange(draft.copyWith(flashlightBlink: v));
          },
        ),
        ListTile(
          title: const Text('Advance reminder'),
          subtitle: Text(draft.advanceMinutes == 0 ? 'None' : '${draft.advanceMinutes}m before'),
          onTap: () async {
            final v = await pickAdvance(context, draft.advanceMinutes);
            if (v != null) onChange(draft.copyWith(advanceMinutes: v));
          },
        ),
        const Divider(),
        const Text('Checklist'),
        for (final item in draft.checklist)
          CheckboxListTile(
            title: Text(item.text),
            value: item.done,
            onChanged: (v) => onChange(draft.copyWith(checklist: draft.checklist.map((e) => e.id == item.id ? e.copyWith(done: v!) : e).toList())),
            secondary: IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => onChange(draft.copyWith(checklist: draft.checklist.where((e) => e.id != item.id).toList())),
            ),
          ),
        Row(
          children: [
            Expanded(child: TextField(controller: checklistCtrl, decoration: const InputDecoration(hintText: 'Add subtask'))),
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: () {
                if (checklistCtrl.text.trim().isEmpty) return;
                onChange(draft.copyWith(checklist: [...draft.checklist, ChecklistItem(id: newId(), text: checklistCtrl.text.trim())]));
                checklistCtrl.clear();
              },
            ),
          ],
        ),
      ],
    );
  }
}
