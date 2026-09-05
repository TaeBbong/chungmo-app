import 'package:flutter/material.dart';

import '../theme/motions.dart';

/// Tap wrapper that scales its child down while pressed.
///
/// The app's cards and tiles sit on flat surfaces where a Material ripple
/// would fight the Toss-style look; a subtle scale is the feedback used
/// instead, applied uniformly through this widget rather than re-implemented
/// per call site. Replaces bare [GestureDetector]s, which gave no feedback
/// at all.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const Pressable({super.key, required this.child, this.onTap});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? Motions.pressedScale : 1.0,
        duration: Motions.quick,
        curve: Motions.easeOut,
        child: widget.child,
      ),
    );
  }
}
