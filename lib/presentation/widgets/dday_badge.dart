import 'package:flutter/material.dart';

import '../../core/utils/date_extension.dart';
import '../theme/palette.dart';

/// `D-23` badge. Past schedules are toned down to grey.
class DDayBadge extends StatelessWidget {
  final DateTime date;

  const DDayBadge({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final bool isPast = date.daysLeft < 0;
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    // Tonal chip: tinted background with an accent label reads lighter than
    // a solid badge, and stays legible in both themes.
    final Color background = isPast
        ? (isLight ? Palette.grey200 : Palette.grey800)
        : (isLight ? Palette.burgundy50 : Palette.burgundy600);
    final Color foreground = isPast
        ? (isLight ? Palette.grey600 : Palette.grey500)
        : (isLight ? Palette.burgundy : Palette.burgundy100);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        date.ddayLabel,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: foreground,
        ),
      ),
    );
  }
}
