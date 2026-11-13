import '../../core/constants/app_enums.dart';

class ReminderTemplate {
  final String label;
  final String title;
  final String note;
  final RepeatType repeatType;
  final int repeatInterval;
  final List<int> repeatWeekdays;
  final int? repeatMonthDay;
  final int hour;
  final int minute;
  final int? activeStartMin;
  final int? activeEndMin;
  final int snoozeMinutes;
  final bool once;

  const ReminderTemplate({
    required this.label,
    required this.title,
    this.note = '',
    this.repeatType = RepeatType.daily,
    this.repeatInterval = 1,
    this.repeatWeekdays = const [],
    this.repeatMonthDay,
    this.hour = 9,
    this.minute = 0,
    this.activeStartMin,
    this.activeEndMin,
    this.snoozeMinutes = 10,
    this.once = false,
  });

  static const all = <ReminderTemplate>[
    ReminderTemplate(
        label: 'Medicine', title: 'Take medicine',
        hour: 8, snoozeMinutes: 5),
    ReminderTemplate(
        label: 'Water', title: 'Drink water',
        repeatType: RepeatType.everyHours, repeatInterval: 2,
        hour: 8, activeStartMin: 480, activeEndMin: 1200),
    ReminderTemplate(
        label: 'Bills', title: 'Pay bills',
        repeatType: RepeatType.monthly, repeatMonthDay: 5, hour: 10),
    ReminderTemplate(
        label: 'Birthday', title: 'Birthday',
        repeatType: RepeatType.yearly),
    ReminderTemplate(
        label: 'Meeting', title: 'Meeting',
        once: true, hour: 10, snoozeMinutes: 5),
  ];
}
