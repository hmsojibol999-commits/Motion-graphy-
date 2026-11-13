import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/home_shell.dart';
import '../../features/onboarding/onboarding_provider.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/permissions_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final onboarded = ref.watch(onboardingProvider).done;
  return GoRouter(
    initialLocation: onboarded ? '/' : '/onboarding',
    redirect: (context, state) {
      final atOnboard = state.matchedLocation.startsWith('/onboarding');
      if (!onboarded && !atOnboard) return '/onboarding';
      if (onboarded && atOnboard) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
        routes: [
          GoRoute(
            path: 'permissions',
            builder: (_, __) => const PermissionsScreen(),
          ),
        ],
      ),
      GoRoute(path: '/', builder: (_, __) => const HomeShell()),
    ],
  );
});
