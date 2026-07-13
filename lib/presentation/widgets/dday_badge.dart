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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPast ? Palette.grey500 : Palette.burgundy,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        date.ddayLabel,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Palette.white,
        ),
      ),
    );
  }
}
