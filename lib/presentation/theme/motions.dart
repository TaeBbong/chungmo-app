import 'package:flutter/animation.dart';

/// Motion tokens: durations and curves every animation composes.
///
/// One vocabulary instead of per-widget numbers keeps the app feeling like
/// a single system — the same reason [Dimens] exists for spacing. Decelerate
/// curves (fast start, gentle stop) are the default because UI motion reacts
/// to a tap: the response should appear immediately and settle, not wind up.
abstract class Motions {
  /// Small state feedback: pressed scale, icon swaps, chip toggles.
  static const Duration quick = Duration(milliseconds: 150);

  /// Screen-level state changes: content switching, elements appearing.
  static const Duration standard = Duration(milliseconds: 250);

  /// One-off emphasis: charts drawing in, numbers counting up.
  static const Duration emphasized = Duration(milliseconds: 600);

  /// Default decelerate curve for anything entering or changing.
  static const Curve easeOut = Curves.easeOutCubic;

  /// Stronger decelerate for [emphasized] moments; most of the change lands
  /// early so long animations still feel responsive.
  static const Curve emphasizedEase = Curves.easeOutQuart;

  /// Pressed-state scale for tappable cards and tiles.
  static const double pressedScale = 0.97;
}
