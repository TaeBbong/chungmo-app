import 'package:flutter/material.dart';

abstract class Palette {
  /// Brand tonal scale — burgundy stays the single chromatic accent.
  static Color burgundy50 = const Color(0xFFFAEEF0);
  static Color burgundy100 = const Color(0xFFF2D7DC);
  static Color burgundy200 = const Color(0xFFE0A8B2);
  static Color burgundy = const Color(0xFF800020); // primary accent
  static Color burgundy600 = const Color(0xFF69001A);

  /// Legacy warm neutrals, kept for the dark theme accents.
  static Color beige = const Color(0xFFF5E6CC); // 베이지
  static Color beige100 = const Color(0xFFFAF1E3);

  /// Achromatic color
  static Color white = const Color(0xFFFFFFFF);
  static Color grey100 = const Color(0xFFFAFAFA);
  static Color grey150 = const Color(0xFFF5F5F5);
  static Color grey200 = const Color(0xFFEFEFEF);
  static Color grey250 = const Color(0xFFE8E8E8);
  static Color grey300 = const Color(0xFFDFDFDF);
  static Color grey400 = const Color(0xFFB7B7B7);
  static Color grey500 = const Color(0xFF949494);
  static Color grey600 = const Color(0xFF777777);
  static Color grey700 = const Color(0xFF555555);
  static Color grey800 = const Color(0xFF2A2A2A);
  static Color grey850 = const Color(0xFF1F1F1F);
  static Color grey900 = const Color(0xFF111111);
  static Color black = const Color(0xFF000000);

  /// Semantic text tones (light theme; dark theme maps its own).
  static Color textPrimary = grey900;
  static Color textSecondary = grey600;
  static Color textTertiary = grey400;

  /// Surfaces — near-white section background under white cards.
  static Color surface = white;
  static Color surfaceMuted = const Color(0xFFF7F7F8);

  /// Status colors.
  static Color error = const Color(0xFFD92D20);
  static Color success = const Color(0xFF12B76A);
}
