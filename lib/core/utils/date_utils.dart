import 'package:intl/intl.dart';

class DateX {
  DateX._();

  static DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  static DateTime addMinutes(DateTime d, int m) => d.add(Duration(minutes: m));

  static String humanDate(DateTime d, {String locale = 'en'}) {
    final today = startOfDay(DateTime.now());
    final target = startOfDay(d);
    final diff = target.difference(today).inDays;
    if (diff == 0) return locale == 'bn' ? 'আজ' : 'Today';
    if (diff == 1) return locale == 'bn' ? 'আগামীকাল' : 'Tomorrow';
    if (diff == -1) return locale == 'bn' ? 'গতকাল' : 'Yesterday';
    return DateFormat.yMMMd(locale).format(d);
  }

  static String humanTime(DateTime d) {
    return DateFormat.jm().format(d);
  }

  static String humanDateTime(DateTime d, {String locale = 'en'}) =>
      '${humanDate(d, locale: locale)} • ${humanTime(d)}';
}
