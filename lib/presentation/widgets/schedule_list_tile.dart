import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/utils/date_converter.dart';
import '../../domain/entities/schedule.dart';
import '../theme/palette.dart';

class ScheduleListTile extends StatelessWidget {
  final Schedule schedule;

  const ScheduleListTile({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
    final String formatDate = DateConverter.generateKrDate(schedule.date);

    return GestureDetector(
      onTap: () {
        Get.toNamed('/detail', arguments: schedule);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Palette.beige, width: 2),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(schedule.thumbnail),
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
            ],
          ),
        ),
      ),
    );
  }
}
