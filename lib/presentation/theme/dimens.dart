/// Spacing / radius / sizing tokens on a 4pt grid.
///
/// Screens should compose these instead of hard-coding numbers, so the
/// rhythm stays consistent across the app.
abstract class Dimens {
  // Spacing
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Default horizontal padding of a screen body.
  static const double screenPadding = 20;

  // Corner radius
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;

  /// Bottom sheets round only their top corners with this radius.
  static const double radiusSheet = 24;

  // Component sizes
  static const double buttonHeight = 56;
  static const double minTouchTarget = 48;
}
