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

  /// Widest a screen body is allowed to grow.
  ///
  /// Beyond this a row stops being readable: on an 11" iPad the D-day badge
  /// ends up a hand's width from the name it belongs to. Phones are never
  /// this wide, so the cap costs them nothing.
  static const double maxContentWidth = 560;

  /// Material's expanded window size class. At or above it there is room for
  /// two panes side by side; below it there is room for one.
  static const double expandedWidth = 840;

  /// Shortest window this app will put two panes in.
  ///
  /// Not a Material height class — those sit at 480 and 900 — but our own
  /// floor, taken from what the screen that uses it needs: a month grid is
  /// about 416dp, and under an app bar with anything left for the list that
  /// wants roughly 600. It is what separates a tablet from a phone held
  /// sideways, which clears the expanded *width* class on its own.
  static const double mediumHeight = 600;

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
