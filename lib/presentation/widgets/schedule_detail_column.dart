import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/utils/date_extension.dart';
import '../../domain/entities/schedule.dart';

class ScheduleDetailColumn extends StatelessWidget {
  final Schedule schedule;
  final List<Widget>? extraChildren;

  const ScheduleDetailColumn({
    super.key,
    required this.schedule,
    this.extraChildren,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 📸 사진
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: CachedNetworkImageProvider(schedule.thumbnail),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 👰‍♀️ & 🤵‍♂️ 신랑 & 신부
        Text(
          '🤵‍♂️ ${schedule.groom} & 👰‍♀️ ${schedule.bride}',
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: 4),

        // 📅 날짜
        Text(
          '📅 ${schedule.date.krDate}',
          style: textTheme.bodyMedium,
        ),

        // 🏡 장소
        SizedBox(
          width: 250,
          child: Text(
            '🏡 ${schedule.location}',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (extraChildren != null) ...extraChildren!,
      ],
    );
  }
}
