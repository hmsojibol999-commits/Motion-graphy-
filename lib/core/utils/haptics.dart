import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';

import '../../features/settings/settings_providers.dart';

class Haptics {
  const Haptics(this._enabled);
  final bool _enabled;

  Future<void> light() async {
    if (!_enabled) return;
    try { await HapticFeedback.lightImpact(); } catch (_) {}
  }

  Future<void> medium() async {
    if (!_enabled) return;
    try { await HapticFeedback.mediumImpact(); } catch (_) {}
  }

  Future<void> pattern(List<int> pattern) async {
    if (!_enabled) return;
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.vibrate(pattern: pattern);
      }
    } catch (_) {}
  }
}

final hapticsProvider = Provider<Haptics>((ref) {
  return Haptics(ref.watch(settingsProvider).haptics);
});
