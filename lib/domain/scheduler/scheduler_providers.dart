import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'android_scheduler.dart';
import 'scheduler_service.dart';

final schedulerServiceProvider = Provider<SchedulerService>((ref) {
  return AndroidScheduler();
});
