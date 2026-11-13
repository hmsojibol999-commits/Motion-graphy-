import 'dart:io';

import 'package:flutter/services.dart';

/// Consumes user actions queued by native side (Done/Snooze/Skip from
/// lock-screen activity or notification buttons while app was closed).
class NativeActionsChannel {
  static const _ch = MethodChannel('com.remindme.remindme/actions');

  void setPendingListener(Future<void> Function() listener) {
    _ch.setMethodCallHandler((call) async {
      if (call.method == 'pendingActionsChanged') await listener();
    });
  }

  Future<List<Map<String, dynamic>>> consumePending() async {
    if (!Platform.isAndroid) return const [];
    try {
      final raw = await _ch.invokeMethod<List<dynamic>>('consumePendingActions');
      if (raw == null) return const [];
      return raw
          .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
