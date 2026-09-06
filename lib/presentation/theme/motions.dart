import 'package:flutter/animation.dart';

/// Motion tokens: durations and curves every animation composes.
///
/// One vocabulary instead of per-widget numbers keeps the app feeling like
/// a single system — the same reason `Dimens` exists for spacing. Decelerate
/// curves (fast start, gentle stop) are the default because UI motion reacts
/// to a tap: the response should appear immediately and settle, not wind up.
abstract class Motions {
  /// Small state feedback: pressed scale, icon swaps, chip toggles.
  static const Duration quick = Duration(milliseconds: 150);

  /// Screen-level state changes: content switching, elements appearing.
  static const Duration standard = Duration(milliseconds: 250);

  /// One-off emphasis: charts drawing in, numbers counting up.
  static const Duration emphasized = Duration(milliseconds: 600);

  /// How long a transient confirmation (the copied check) stays before
  /// reverting.
  static const Duration hold = Duration(seconds: 2);

  /// Offset between staggered entrances, e.g. content following a header.
  static const Duration stagger = Duration(milliseconds: 100);

  /// Default decelerate curve for anything entering or changing.
  static const Curve easeOut = Curves.easeOutCubic;

  /// Stronger decelerate for [emphasized] moments; most of the change lands
  /// early so long animations still feel responsive.
  static const Curve emphasizedEase = Curves.easeOutQuart;

  /// Pressed-state scale for tappable cards and tiles.
  static const double pressedScale = 0.97;

  /// Starting scale of content emerging through a switcher transition.
  static const double emergeScale = 0.98;

  /// Vertical travel, in logical pixels, of content sliding in.
  static const double slideOffset = 16;
}
