import 'package:flutter/material.dart';

import '../theme/dimens.dart';

/// Caps how wide a screen body may grow, and centres it once it is capped.
///
/// The app ships to iPad and to Android split-screen, where a phone layout
/// stretched across the window turns every row into a journey: the name on
/// the left, the badge on the right, nothing in between. Capping the body is
/// the standard answer for a content-centric app — the alternative, letting
/// rows grow, has nothing to put in the space.
///
/// Below [maxWidth] this returns the child untouched, with no extra widget in
/// the tree, so phone layouts are unchanged rather than merely unaffected.
class AdaptiveBody extends StatelessWidget {
  final Widget child;

  /// Defaults to [Dimens.maxContentWidth]; a wider pane (a two-pane screen,
  /// say) can ask for more.
  final double maxWidth;

  /// Where the capped body sits in the extra space. Bodies centre; a pane in
  /// a two-pane layout usually hugs its own side.
  final AlignmentGeometry alignment;

  const AdaptiveBody({
    super.key,
    required this.child,
    this.maxWidth = Dimens.maxContentWidth,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= maxWidth) return child;
        return Align(
          alignment: alignment,
          // Take the child's height rather than the whole viewport, so this
          // works in a bottom sheet as well as in a body. A body's child is
          // a full-height column either way, so nothing is lost there.
          heightFactor: 1,
          // A tight width, not a maximum: the child should fill the capped
          // body rather than shrink-wrap inside it.
          child: SizedBox(width: maxWidth, child: child),
        );
      },
    );
  }
}

/// Whether [context] has room for two panes side by side.
///
/// Width alone is not the question. A phone held sideways is 844dp wide and
/// 390dp tall: wide enough to clear Material's expanded width class on its
/// own, far too short to put a month grid and a list beside each other. Both
/// axes have to be roomy, which is what separates a tablet from a rotated
/// phone. See [Dimens.mediumHeight] for where the height floor comes from.
bool hasRoomForTwoPanes(BuildContext context) {
  final Size size = MediaQuery.sizeOf(context);
  return size.width >= Dimens.expandedWidth &&
      size.height >= Dimens.mediumHeight;
}
