import 'package:flutter/material.dart';

import '../theme/motions.dart';

/// One-shot entrance: fades the child in while sliding it up a step.
///
/// [delay] holds the child invisible first, so content can enter after a
/// hero flight or in a stagger. Implemented on TweenAnimationBuilder — the
/// delay is the leading, clamped-to-zero part of one longer tween, which
/// keeps this a plain implicit animation with no controller to manage.
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final Duration delay;

  const FadeSlideIn({super.key, required this.child, this.delay = Duration.zero});

  @override
  Widget build(BuildContext context) {
    final Duration total = delay + Motions.standard;
    final double delayFraction = delay.inMilliseconds / total.inMilliseconds;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: total,
      builder: (BuildContext context, double t, Widget? child) {
        final double local = delayFraction == 1
            ? 1
            : Motions.easeOut.transform(
                ((t - delayFraction) / (1 - delayFraction)).clamp(0, 1));
        return Opacity(
          opacity: local,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - local)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
