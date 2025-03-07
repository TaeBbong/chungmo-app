import 'package:flutter/material.dart';

import '../../core/utils/date_converter.dart';
import '../../domain/entities/schedule.dart';

class ScheduleDetailColumn extends StatelessWidget {
  final Schedule schedule;
  final List<Widget>? extraChildren;

  const ScheduleDetailColumn(
      {super.key, required this.schedule, this.extraChildren});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: NetworkImage(schedule.thumbnail),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${schedule.groom} & ${schedule.bride}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          DateConverter.generateKrDate(schedule.date),
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        SizedBox(
          width: 250,
          child: Text(
            schedule.location,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (extraChildren != null) ...extraChildren!,
      ],
    );
  }
}
