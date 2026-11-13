import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class TimezoneHelper {
  TimezoneHelper._();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    try {
      final id = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(id));
    } catch (_) {}
    _initialized = true;
  }

  static tz.Location get location => tz.local;
}
