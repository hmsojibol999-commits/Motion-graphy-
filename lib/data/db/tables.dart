import 'package:drift/drift.dart';

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get colorHex => text().withDefault(const Constant('#6366F1'))();
  TextColumn get iconName => text().withDefault(const Constant('folder'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get dueAt => integer()();
  TextColumn get categoryId => text().nullable()();

  /// 0=none,1=low,2=medium,3=high
  IntColumn get priority => integer().withDefault(const Constant(0))();

  // ---- repeat rule ----
  /// 0=once,1=everyMinutes,2=everyHours,3=daily,4=weekly,
  /// 5=monthly,6=lastDayOfMonth,7=nthWeekdayOfMonth,8=yearly
  IntColumn get repeatType => integer().withDefault(const Constant(0))();
  IntColumn get repeatInterval => integer().withDefault(const Constant(1))();
  TextColumn get repeatWeekdaysCsv => text().withDefault(const Constant(''))();
  IntColumn get repeatMonthDay => integer().nullable()();
  IntColumn get repeatNth => integer().nullable()();
  IntColumn get repeatNthWeekday => integer().nullable()();
  /// 0=never,1=untilDate,2=afterCount
  IntColumn get repeatEndType => integer().withDefault(const Constant(0))();
  IntColumn get repeatEndDate => integer().nullable()();
  IntColumn get repeatEndCount => integer().nullable()();
  IntColumn get firedCount => integer().withDefault(const Constant(0))();

  // ---- active window (minutes since midnight; null = all day) ----
  IntColumn get activeStartMin => integer().nullable()();
  IntColumn get activeEndMin => integer().nullable()();

  IntColumn get advanceMinutes => integer().withDefault(const Constant(0))();

  // ---- alert ----
  /// 0=notification,1=fullScreenAlarm
  IntColumn get alertType => integer().withDefault(const Constant(0))();
  TextColumn get soundPath => text().nullable()();
  TextColumn get soundName => text().nullable()();
  /// 0=short,1=long,2=custom
  IntColumn get vibrationType => integer().withDefault(const Constant(0))();
  TextColumn get vibrationPatternCsv => text().nullable()();
  BoolColumn get flashlightBlink =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get ttsRead => boolean().withDefault(const Constant(false))();
  BoolColumn get gradualVolume =>
      boolean().withDefault(const Constant(false))();
  IntColumn get volumeLevel => integer().withDefault(const Constant(100))();
  IntColumn get ringDurationSec => integer().withDefault(const Constant(30))();
  IntColumn get ringRepeatCount => integer().withDefault(const Constant(3))();
  IntColumn get snoozeMinutes => integer().withDefault(const Constant(10))();
  IntColumn get maxSnoozeCount => integer().withDefault(const Constant(5))();
  IntColumn get currentSnoozeCount => integer().withDefault(const Constant(0))();
  /// 0=none,1=math,2=shake
  IntColumn get dismissChallenge => integer().withDefault(const Constant(0))();

  // ---- status ----
  /// 0=active,1=completed,2=snoozed,3=missed,4=archived,5=trashed
  IntColumn get status => integer().withDefault(const Constant(0))();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();

  // ---- scheduling ----
  IntColumn get nextFireAt => integer().nullable()();
  TextColumn get notificationIdsCsv =>
      text().withDefault(const Constant(''))();

  // ---- complex payloads ----
  TextColumn get checklistJson => text().withDefault(const Constant('[]'))();
  TextColumn get attachmentsJson => text().withDefault(const Constant('[]'))();

  // ---- lifecycle ----
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get completedAt => integer().nullable()();
  IntColumn get snoozedUntil => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
