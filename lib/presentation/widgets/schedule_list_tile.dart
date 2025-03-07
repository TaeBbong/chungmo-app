import 'package:flutter/material.dart';

import '../../core/utils/date_converter.dart';
import '../../domain/entities/schedule.dart';
import '../theme/palette.dart';

class ScheduleListTile extends StatelessWidget {
  final Schedule schedule;

  const ScheduleListTile({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
    final String formatDate = DateConverter.generateKrDate(schedule.date);

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
