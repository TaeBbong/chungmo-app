import 'package:flutter/material.dart';

import '../theme/palette.dart';

/// Metrics and text styles of a single row in the detail card.
///
/// Kept in one place because the rows must share a grid: the icon column, the
/// label column and the value column have to line up across every row,
/// including the expandable account row.
abstract class InfoRowMetrics {
  static const double iconSize = 20;
  static const double iconGap = 12;
  static const double labelWidth = 44;

  /// Height of one line of [valueStyle]. Icons are centered within it so they
  /// sit on the value's first line.
  static const double lineHeight = 22;

  /// Where the value column starts; expanded content is indented to match.
  static const double valueOffset = iconSize + iconGap + labelWidth;

  static const TextStyle labelStyle = TextStyle(fontSize: 13);
  static const TextStyle valueStyle =
      TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
  static const TextStyle hintStyle = TextStyle(fontSize: 12);
}

/// A row of the detail card: `[icon] label   value`.
///
/// The label(13) and the value(14) differ in size, so aligning their tops makes
/// the text look off; their first lines are aligned by baseline instead.
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? hint;
  final Color? valueColor;
  final VoidCallback? onTap;

  /// When non-null the row expands to reveal these, indented to the value
  /// column. Mutually exclusive with [onTap].
  final List<Widget>? expandedChildren;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.hint,
    this.valueColor,
    this.onTap,
  }) : expandedChildren = null;

  /// A row that expands to reveal [expandedChildren], e.g. the account list.
  const InfoRow.expandable({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required List<Widget> children,
  })  : expandedChildren = children,
        hint = null,
        valueColor = null,
        onTap = null;

  @override
  Widget build(BuildContext context) {
    if (expandedChildren != null) {
      return Theme(
        // The default trailing icon follows the theme's primary color, which
        // makes it the only colored thing in the card once expanded.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(
            left: InfoRowMetrics.valueOffset,
            bottom: 12,
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: Palette.grey600,
          collapsedIconColor: Palette.grey600,
          title: _content(),
          children: expandedChildren!,
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: _content(),
      ),
    );
  }

  Widget _content() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // An Icon has no baseline, so it is centered in a box the height of the
        // value's first line instead of being baseline-aligned.
        SizedBox(
          height: InfoRowMetrics.lineHeight,
          child: Icon(
            icon,
            size: InfoRowMetrics.iconSize,
            color: Palette.grey600,
          ),
        ),
        const SizedBox(width: InfoRowMetrics.iconGap),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              SizedBox(
                width: InfoRowMetrics.labelWidth,
                child: Text(
                  label,
                  style: InfoRowMetrics.labelStyle
                      .copyWith(color: Palette.grey600),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style:
                          InfoRowMetrics.valueStyle.copyWith(color: valueColor),
                    ),
                    if (hint != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          hint!,
                          style: InfoRowMetrics.hintStyle
                              .copyWith(color: Palette.grey500),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
