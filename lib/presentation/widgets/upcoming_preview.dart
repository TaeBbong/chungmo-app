import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/navigation/app_navigation.dart';
import '../../core/utils/date_extension.dart';
import '../../domain/entities/schedule.dart';
import '../theme/palette.dart';
import 'dday_badge.dart';

/// Preview of what is coming up, shown on the home screen while it waits for
/// a link. Renders nothing when there is nothing upcoming.
class UpcomingPreview extends StatelessWidget {
  final List<Schedule> schedules;

  /// The home screen is not a list screen; only the nearest few belong here.
  static const int maxCount = 3;

  const UpcomingPreview({super.key, required this.schedules});

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) return const SizedBox.shrink();

    final List<Schedule> preview = schedules.take(maxCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '다가오는 일정',
            style: TextStyle(fontSize: 13, color: Palette.grey600),
          ),
        ),
        ...preview.map((schedule) => _PreviewTile(schedule: schedule)),
      ],
    );
  }
}

class _PreviewTile extends StatelessWidget {
  final Schedule schedule;

  const _PreviewTile({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        navigatorKey.currentState?.pushNamed('/detail', arguments: schedule);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Palette.beige100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.transparent,
              backgroundImage: CachedNetworkImageProvider(schedule.thumbnail),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${schedule.groom} & ${schedule.bride}',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    schedule.date.krDate,
                    style: TextStyle(fontSize: 12, color: Palette.grey600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            DDayBadge(date: schedule.date),
          ],
        ),
      ),
    );
  }
}
