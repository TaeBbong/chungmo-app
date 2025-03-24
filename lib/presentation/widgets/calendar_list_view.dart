import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/calendar_viewmodel.dart';
import 'schedule_list_tile.dart';

class CalendarListView extends StatelessWidget {
  final CalendarController _controller = Get.find<CalendarController>();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Obx(() {
            if (_controller.allSchedules.value!.isEmpty) {
              return const Center(child: Text("일정이 없습니다."));
            }

            final now = DateTime.now();
            final pastSchedules = _controller.allSchedules.value!
                .where((s) => DateTime.parse(s.date).isBefore(now))
                .toList();

            final upcomingSchedules = _controller.allSchedules.value!
                .where((s) => !DateTime.parse(s.date).isBefore(now))
                .toList();

            return ListView(
              children: [
                if (upcomingSchedules.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "앞으로의 일정",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...upcomingSchedules
                      .map((schedule) => ScheduleListTile(schedule: schedule)),
                ],
                if (pastSchedules.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "지난 일정",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...pastSchedules
                      .map((schedule) => ScheduleListTile(schedule: schedule)),
                ],
              ],
            );
          }),
        ),
      ],
    );
  }
}
