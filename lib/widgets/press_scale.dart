import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_spacing.dart';
import '../core/utils/haptics.dart';

/// Wraps any widget with a subtle press-scale (0.97) + light haptic.
class PressScale extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final bool haptic;
  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.haptic = true,
  });

  @override
  ConsumerState<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends ConsumerState<PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        if (widget.haptic) ref.read(hapticsProvider).light();
        widget.onTap?.call();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        child: widget.child,
      ),
    );
  }
}
