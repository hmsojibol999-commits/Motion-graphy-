import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../settings/settings_providers.dart';

class OnboardingState {
  final bool done;
  const OnboardingState(this.done);
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier(this._ref)
      : super(OnboardingState(
          _ref.read(sharedPrefsProvider).getBool(AppConstants.prefOnboarded) ??
              false,
        ));

  final Ref _ref;

  Future<void> complete() async {
    await _ref
        .read(sharedPrefsProvider)
        .setBool(AppConstants.prefOnboarded, true);
    state = const OnboardingState(true);
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(ref);
});
