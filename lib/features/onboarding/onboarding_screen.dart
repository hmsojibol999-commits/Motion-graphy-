import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import 'onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = [
    (
      'Never forget again',
      'Set reminders in seconds. They fire even when the app is closed.',
      Icons.alarm,
    ),
    (
      'Rings like a real alarm',
      'Full-screen alarm on your lock screen, custom sound, vibration, even TTS.',
      Icons.notifications_active,
    ),
    (
      '100% offline',
      'Your data stays on your device. No account. No internet. No ads.',
      Icons.lock_outline,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(s.$3, size: 96, color: t.colorScheme.primary),
                        const SizedBox(height: AppSpacing.lg),
                        Text(s.$1,
                            style: t.textTheme.headlineMedium,
                            textAlign: TextAlign.center),
                        const SizedBox(height: AppSpacing.md),
                        Text(s.$2,
                            style: t.textTheme.bodyLarge?.copyWith(
                                color: t.colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _index
                        ? t.colorScheme.primary
                        : t.colorScheme.onSurface.withOpacity(0.2),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  if (_index > 0)
                    TextButton(
                      onPressed: () => _controller.previousPage(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                      ),
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () async {
                      if (_index < _slides.length - 1) {
                        await _controller.nextPage(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                        );
                      } else {
                        if (mounted) context.go('/onboarding/permissions');
                      }
                    },
                    child: Text(_index == _slides.length - 1
                        ? 'Continue'
                        : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
