import 'package:flutter/material.dart';

/// Pretendard type scale.
///
/// Colors are intentionally omitted — apply semantic tones from the theme
/// (`textPrimary` 등) at the call site, so the same scale works in both
/// light and dark themes.
abstract class AppTypography {
  static const String fontFamily = 'Pretendard';

  /// Screen-level greeting / hero title.
  static const TextStyle display = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  /// Page titles and section headers.
  static const TextStyle headline = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.35,
  );

  /// Card titles, dialog titles, emphasized rows.
  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// Default body text.
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// Secondary body text.
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  /// Helper text, timestamps, badges.
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// Buttons and other tappable labels.
  static const TextStyle label = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
}
