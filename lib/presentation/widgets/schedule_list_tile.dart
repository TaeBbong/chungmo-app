import 'package:flutter/material.dart';

import '../../core/utils/constants.dart';
import '../../domain/entities/schedule.dart';
import '../theme/palette.dart';

class ScheduleListTile extends StatelessWidget {
  final Schedule schedule;

  const ScheduleListTile({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
    final DateTime dateTime = DateTime.parse(schedule.date);
    String formatDate =
        '${dateTime.month}월 ${dateTime.day}일(${Constants.weekdays[dateTime.weekday - 1]}) ${dateTime.hour}시';
    if (dateTime.minute != 0) formatDate += '${dateTime.minute}분';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.beige, width: 2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
        leading: CircleAvatar(
          backgroundImage: NetworkImage(schedule.thumbnail),
          backgroundColor: Colors.transparent,
        ),
        title: Text('${schedule.groom} & ${schedule.bride}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatDate,
              style: const TextStyle(fontSize: 12),
            ),
            SizedBox(
              width: 250,
              child: Text(
                schedule.location,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
