import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/constants/app_enums.dart';
import '../../data/db/database.dart';
import 'attachment.dart';
import 'checklist_item.dart';

class ReminderEntity {
  final String id;
  final String title;
  final String note;
  final DateTime dueAt;
  final String? categoryId;
  final Priority priority;

  final RepeatType repeatType;
  final int repeatInterval;
  final List<int> repeatWeekdays; // 1=Mon..7=Sun
  final int? repeatMonthDay;
  final int? repeatNth;
  final int? repeatNthWeekday;
  final RepeatEnd repeatEndType;
  final DateTime? repeatEndDate;
  final int? repeatEndCount;
  final int firedCount;

  final int? activeStartMin;
  final int? activeEndMin;
  final int advanceMinutes;

  final AlertType alertType;
  final String? soundPath;
  final String? soundName;
  final VibrationPatternType vibrationType;
  final List<int> vibrationPattern;
  final bool flashlightBlink;
  final bool ttsRead;
  final bool gradualVolume;
  final int volumeLevel;
  final int ringDurationSec;
  final int ringRepeatCount;
  final int snoozeMinutes;
  final int maxSnoozeCount;
  final int currentSnoozeCount;
  final int dismissChallenge; // 0=none,1=math,2=shake

  final ReminderStatus status;
  final bool pinned;
  final DateTime? nextFireAt;
  final List<int> notificationIds;

  final List<ChecklistItem> checklist;
  final List<Attachment> attachments;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? snoozedUntil;

  const ReminderEntity({
    required this.id,
    required this.title,
    required this.note,
    required this.dueAt,
    this.categoryId,
    this.priority = Priority.none,
    this.repeatType = RepeatType.once,
    this.repeatInterval = 1,
    this.repeatWeekdays = const [],
    this.repeatMonthDay,
    this.repeatNth,
    this.repeatNthWeekday,
    this.repeatEndType = RepeatEnd.never,
    this.repeatEndDate,
    this.repeatEndCount,
    this.firedCount = 0,
    this.activeStartMin,
    this.activeEndMin,
    this.advanceMinutes = 0,
    this.alertType = AlertType.notification,
    this.soundPath,
    this.soundName,
    this.vibrationType = VibrationPatternType.short,
    this.vibrationPattern = const [],
    this.flashlightBlink = false,
    this.ttsRead = false,
    this.gradualVolume = false,
    this.volumeLevel = 100,
    this.ringDurationSec = 30,
    this.ringRepeatCount = 3,
    this.snoozeMinutes = 10,
    this.maxSnoozeCount = 5,
    this.currentSnoozeCount = 0,
    this.dismissChallenge = 0,
    this.status = ReminderStatus.active,
    this.pinned = false,
    this.nextFireAt,
    this.notificationIds = const [],
    this.checklist = const [],
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.snoozedUntil,
  });

  bool get isActive => status == ReminderStatus.active;
  bool get isDone => status == ReminderStatus.completed;
  bool get isTrashed => status == ReminderStatus.trashed;

  /// The occurrence shown in lists/calendars. `dueAt` remains the immutable
  /// recurrence anchor; the next alarm and any active snooze have their own dates.
  DateTime get occurrenceAt => status == ReminderStatus.snoozed &&
          snoozedUntil != null
      ? snoozedUntil!
      : (nextFireAt ?? dueAt);

  bool get isOverdue =>
      status == ReminderStatus.active && occurrenceAt.isBefore(DateTime.now());

  ReminderEntity copyWith({
    String? title,
    String? note,
    DateTime? dueAt,
    Object? categoryId = _s,
    Priority? priority,
    RepeatType? repeatType,
    int? repeatInterval,
    List<int>? repeatWeekdays,
    Object? repeatMonthDay = _s,
    Object? repeatNth = _s,
    Object? repeatNthWeekday = _s,
    RepeatEnd? repeatEndType,
    Object? repeatEndDate = _s,
    Object? repeatEndCount = _s,
    int? firedCount,
    Object? activeStartMin = _s,
    Object? activeEndMin = _s,
    int? advanceMinutes,
    AlertType? alertType,
    Object? soundPath = _s,
    Object? soundName = _s,
    VibrationPatternType? vibrationType,
    List<int>? vibrationPattern,
    bool? flashlightBlink,
    bool? ttsRead,
    bool? gradualVolume,
    int? volumeLevel,
    int? ringDurationSec,
    int? ringRepeatCount,
    int? snoozeMinutes,
    int? maxSnoozeCount,
    int? currentSnoozeCount,
    int? dismissChallenge,
    ReminderStatus? status,
    bool? pinned,
    Object? nextFireAt = _s,
    List<int>? notificationIds,
    List<ChecklistItem>? checklist,
    List<Attachment>? attachments,
    DateTime? updatedAt,
    Object? completedAt = _s,
    Object? snoozedUntil = _s,
  }) =>
      ReminderEntity(
        id: id,
        title: title ?? this.title,
        note: note ?? this.note,
        dueAt: dueAt ?? this.dueAt,
        categoryId:
            categoryId == _s ? this.categoryId : categoryId as String?,
        priority: priority ?? this.priority,
        repeatType: repeatType ?? this.repeatType,
        repeatInterval: repeatInterval ?? this.repeatInterval,
        repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
        repeatMonthDay: repeatMonthDay == _s
            ? this.repeatMonthDay
            : repeatMonthDay as int?,
        repeatNth: repeatNth == _s ? this.repeatNth : repeatNth as int?,
        repeatNthWeekday: repeatNthWeekday == _s
            ? this.repeatNthWeekday
            : repeatNthWeekday as int?,
        repeatEndType: repeatEndType ?? this.repeatEndType,
        repeatEndDate: repeatEndDate == _s
            ? this.repeatEndDate
            : repeatEndDate as DateTime?,
        repeatEndCount: repeatEndCount == _s
            ? this.repeatEndCount
            : repeatEndCount as int?,
        firedCount: firedCount ?? this.firedCount,
        activeStartMin: activeStartMin == _s
            ? this.activeStartMin
            : activeStartMin as int?,
        activeEndMin: activeEndMin == _s
            ? this.activeEndMin
            : activeEndMin as int?,
        advanceMinutes: advanceMinutes ?? this.advanceMinutes,
        alertType: alertType ?? this.alertType,
        soundPath: soundPath == _s ? this.soundPath : soundPath as String?,
        soundName: soundName == _s ? this.soundName : soundName as String?,
        vibrationType: vibrationType ?? this.vibrationType,
        vibrationPattern: vibrationPattern ?? this.vibrationPattern,
        flashlightBlink: flashlightBlink ?? this.flashlightBlink,
        ttsRead: ttsRead ?? this.ttsRead,
        gradualVolume: gradualVolume ?? this.gradualVolume,
        volumeLevel: volumeLevel ?? this.volumeLevel,
        ringDurationSec: ringDurationSec ?? this.ringDurationSec,
        ringRepeatCount: ringRepeatCount ?? this.ringRepeatCount,
        snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
        maxSnoozeCount: maxSnoozeCount ?? this.maxSnoozeCount,
        currentSnoozeCount: currentSnoozeCount ?? this.currentSnoozeCount,
        dismissChallenge: dismissChallenge ?? this.dismissChallenge,
        status: status ?? this.status,
        pinned: pinned ?? this.pinned,
        nextFireAt: nextFireAt == _s
            ? this.nextFireAt
            : nextFireAt as DateTime?,
        notificationIds: notificationIds ?? this.notificationIds,
        checklist: checklist ?? this.checklist,
        attachments: attachments ?? this.attachments,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        completedAt:
            completedAt == _s ? this.completedAt : completedAt as DateTime?,
        snoozedUntil:
            snoozedUntil == _s ? this.snoozedUntil : snoozedUntil as DateTime?,
      );

  factory ReminderEntity.fromRow(Reminder r) {
    final checklistRaw = jsonDecode(r.checklistJson) as List<dynamic>;
    final attachRaw = jsonDecode(r.attachmentsJson) as List<dynamic>;
    return ReminderEntity(
      id: r.id,
      title: r.title,
      note: r.note,
      dueAt: DateTime.fromMillisecondsSinceEpoch(r.dueAt),
      categoryId: r.categoryId,
      priority: Priority.values[r.priority],
      repeatType: RepeatType.values[r.repeatType],
      repeatInterval: r.repeatInterval,
      repeatWeekdays: r.repeatWeekdaysCsv.isEmpty
          ? const []
          : r.repeatWeekdaysCsv.split(',').map(int.parse).toList(),
      repeatMonthDay: r.repeatMonthDay,
      repeatNth: r.repeatNth,
      repeatNthWeekday: r.repeatNthWeekday,
      repeatEndType: RepeatEnd.values[r.repeatEndType],
      repeatEndDate: r.repeatEndDate == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(r.repeatEndDate!),
      repeatEndCount: r.repeatEndCount,
      firedCount: r.firedCount,
      activeStartMin: r.activeStartMin,
      activeEndMin: r.activeEndMin,
      advanceMinutes: r.advanceMinutes,
      alertType: AlertType.values[r.alertType],
      soundPath: r.soundPath,
      soundName: r.soundName,
      vibrationType: VibrationPatternType.values[r.vibrationType],
      vibrationPattern: (r.vibrationPatternCsv ?? '').isEmpty
          ? const []
          : r.vibrationPatternCsv!.split(',').map(int.parse).toList(),
      flashlightBlink: r.flashlightBlink,
      ttsRead: r.ttsRead,
      gradualVolume: r.gradualVolume,
      volumeLevel: r.volumeLevel,
      ringDurationSec: r.ringDurationSec,
      ringRepeatCount: r.ringRepeatCount,
      snoozeMinutes: r.snoozeMinutes,
      maxSnoozeCount: r.maxSnoozeCount,
      currentSnoozeCount: r.currentSnoozeCount,
      dismissChallenge: r.dismissChallenge,
      status: ReminderStatus.values[r.status],
      pinned: r.pinned,
      nextFireAt: r.nextFireAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(r.nextFireAt!),
      notificationIds: r.notificationIdsCsv.isEmpty
          ? const []
          : r.notificationIdsCsv.split(',').map(int.parse).toList(),
      checklist: checklistRaw
          .map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      attachments: attachRaw
          .map((e) => Attachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt),
      completedAt: r.completedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(r.completedAt!),
      snoozedUntil: r.snoozedUntil == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(r.snoozedUntil!),
    );
  }

  /// Stable, versionable backup representation. Dates are epoch milliseconds
  /// so the file remains independent of the device's display locale.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'dueAt': dueAt.millisecondsSinceEpoch,
        'categoryId': categoryId,
        'priority': priority.name,
        'repeatType': repeatType.name,
        'repeatInterval': repeatInterval,
        'repeatWeekdays': repeatWeekdays,
        'repeatMonthDay': repeatMonthDay,
        'repeatNth': repeatNth,
        'repeatNthWeekday': repeatNthWeekday,
        'repeatEndType': repeatEndType.name,
        'repeatEndDate': repeatEndDate?.millisecondsSinceEpoch,
        'repeatEndCount': repeatEndCount,
        'firedCount': firedCount,
        'activeStartMin': activeStartMin,
        'activeEndMin': activeEndMin,
        'advanceMinutes': advanceMinutes,
        'alertType': alertType.name,
        'soundPath': soundPath,
        'soundName': soundName,
        'vibrationType': vibrationType.name,
        'vibrationPattern': vibrationPattern,
        'flashlightBlink': flashlightBlink,
        'ttsRead': ttsRead,
        'gradualVolume': gradualVolume,
        'volumeLevel': volumeLevel,
        'ringDurationSec': ringDurationSec,
        'ringRepeatCount': ringRepeatCount,
        'snoozeMinutes': snoozeMinutes,
        'maxSnoozeCount': maxSnoozeCount,
        'currentSnoozeCount': currentSnoozeCount,
        'dismissChallenge': dismissChallenge,
        'status': status.name,
        'pinned': pinned,
        'nextFireAt': nextFireAt?.millisecondsSinceEpoch,
        'notificationIds': notificationIds,
        'checklist': checklist.map((e) => e.toJson()).toList(),
        'attachments': attachments.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
        'completedAt': completedAt?.millisecondsSinceEpoch,
        'snoozedUntil': snoozedUntil?.millisecondsSinceEpoch,
      };

  factory ReminderEntity.fromJson(Map<String, dynamic> json) {
    DateTime readDate(Object? value, {DateTime? fallback}) {
      if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      return fallback ?? DateTime.now();
    }

    DateTime? readOptionalDate(Object? value) {
      if (value == null) return null;
      return readDate(value);
    }

    T readEnum<T extends Enum>(List<T> values, Object? value, T fallback) {
      if (value is String) {
        for (final item in values) {
          if (item.name == value) return item;
        }
      }
      if (value is num && value.toInt() >= 0 && value.toInt() < values.length) {
        return values[value.toInt()];
      }
      return fallback;
    }

    List<int> readInts(Object? value) => value is List
        ? value.whereType<num>().map((e) => e.toInt()).toList()
        : const <int>[];

    List<Map<String, dynamic>> readMaps(Object? value) => value is List
        ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : const <Map<String, dynamic>>[];

    final now = DateTime.now();
    return ReminderEntity(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      note: json['note'] as String? ?? '',
      dueAt: readDate(json['dueAt'] ?? json['dueAtMs'], fallback: now),
      categoryId: json['categoryId'] as String?,
      priority: readEnum(Priority.values, json['priority'], Priority.none),
      repeatType: readEnum(RepeatType.values, json['repeatType'], RepeatType.once),
      repeatInterval: (json['repeatInterval'] as num?)?.toInt() ?? 1,
      repeatWeekdays: readInts(json['repeatWeekdays']),
      repeatMonthDay: (json['repeatMonthDay'] as num?)?.toInt(),
      repeatNth: (json['repeatNth'] as num?)?.toInt(),
      repeatNthWeekday: (json['repeatNthWeekday'] as num?)?.toInt(),
      repeatEndType: readEnum(RepeatEnd.values, json['repeatEndType'], RepeatEnd.never),
      repeatEndDate: readOptionalDate(json['repeatEndDate']),
      repeatEndCount: (json['repeatEndCount'] as num?)?.toInt(),
      firedCount: (json['firedCount'] as num?)?.toInt() ?? 0,
      activeStartMin: (json['activeStartMin'] as num?)?.toInt(),
      activeEndMin: (json['activeEndMin'] as num?)?.toInt(),
      advanceMinutes: (json['advanceMinutes'] as num?)?.toInt() ?? 0,
      alertType: readEnum(AlertType.values, json['alertType'], AlertType.notification),
      soundPath: json['soundPath'] as String?,
      soundName: json['soundName'] as String?,
      vibrationType: readEnum(VibrationPatternType.values, json['vibrationType'], VibrationPatternType.short),
      vibrationPattern: readInts(json['vibrationPattern']),
      flashlightBlink: json['flashlightBlink'] as bool? ?? false,
      ttsRead: json['ttsRead'] as bool? ?? false,
      gradualVolume: json['gradualVolume'] as bool? ?? false,
      volumeLevel: (json['volumeLevel'] as num?)?.toInt() ?? 100,
      ringDurationSec: (json['ringDurationSec'] as num?)?.toInt() ?? 30,
      ringRepeatCount: (json['ringRepeatCount'] as num?)?.toInt() ?? 3,
      snoozeMinutes: (json['snoozeMinutes'] as num?)?.toInt() ?? 10,
      maxSnoozeCount: (json['maxSnoozeCount'] as num?)?.toInt() ?? 5,
      currentSnoozeCount: (json['currentSnoozeCount'] as num?)?.toInt() ?? 0,
      dismissChallenge: (json['dismissChallenge'] as num?)?.toInt() ?? 0,
      status: readEnum(ReminderStatus.values, json['status'], ReminderStatus.active),
      pinned: json['pinned'] as bool? ?? false,
      nextFireAt: readOptionalDate(json['nextFireAt']),
      notificationIds: readInts(json['notificationIds']),
      checklist: readMaps(json['checklist']).map(ChecklistItem.fromJson).toList(),
      attachments: readMaps(json['attachments']).map(Attachment.fromJson).toList(),
      createdAt: readDate(json['createdAt'], fallback: now),
      updatedAt: readDate(json['updatedAt'], fallback: now),
      completedAt: readOptionalDate(json['completedAt']),
      snoozedUntil: readOptionalDate(json['snoozedUntil']),
    );
  }

  RemindersCompanion toCompanion() => RemindersCompanion(
        id: Value(id),
        title: Value(title),
        note: Value(note),
        dueAt: Value(dueAt.millisecondsSinceEpoch),
        categoryId: Value(categoryId),
        priority: Value(priority.index),
        repeatType: Value(repeatType.index),
        repeatInterval: Value(repeatInterval),
        repeatWeekdaysCsv: Value(repeatWeekdays.join(',')),
        repeatMonthDay: Value(repeatMonthDay),
        repeatNth: Value(repeatNth),
        repeatNthWeekday: Value(repeatNthWeekday),
        repeatEndType: Value(repeatEndType.index),
        repeatEndDate: Value(repeatEndDate?.millisecondsSinceEpoch),
        repeatEndCount: Value(repeatEndCount),
        firedCount: Value(firedCount),
        activeStartMin: Value(activeStartMin),
        activeEndMin: Value(activeEndMin),
        advanceMinutes: Value(advanceMinutes),
        alertType: Value(alertType.index),
        soundPath: Value(soundPath),
        soundName: Value(soundName),
        vibrationType: Value(vibrationType.index),
        vibrationPatternCsv: Value(vibrationPattern.join(',')),
        flashlightBlink: Value(flashlightBlink),
        ttsRead: Value(ttsRead),
        gradualVolume: Value(gradualVolume),
        volumeLevel: Value(volumeLevel),
        ringDurationSec: Value(ringDurationSec),
        ringRepeatCount: Value(ringRepeatCount),
        snoozeMinutes: Value(snoozeMinutes),
        maxSnoozeCount: Value(maxSnoozeCount),
        currentSnoozeCount: Value(currentSnoozeCount),
        dismissChallenge: Value(dismissChallenge),
        status: Value(status.index),
        pinned: Value(pinned),
        nextFireAt: Value(nextFireAt?.millisecondsSinceEpoch),
        notificationIdsCsv: Value(notificationIds.join(',')),
        checklistJson: Value(
          jsonEncode(checklist.map((e) => e.toJson()).toList()),
        ),
        attachmentsJson: Value(
          jsonEncode(attachments.map((e) => e.toJson()).toList()),
        ),
        createdAt: Value(createdAt.millisecondsSinceEpoch),
        updatedAt: Value(updatedAt.millisecondsSinceEpoch),
        completedAt: Value(completedAt?.millisecondsSinceEpoch),
        snoozedUntil: Value(snoozedUntil?.millisecondsSinceEpoch),
      );
}

const Object _s = Object();
