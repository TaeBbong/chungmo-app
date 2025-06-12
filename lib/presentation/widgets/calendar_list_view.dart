import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/calendar/calendar_bloc.dart';
import '../bloc/calendar/calendar_state.dart';
import 'schedule_list_tile.dart';

class CalendarListView extends StatelessWidget {
  const CalendarListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: BlocBuilder<CalendarBloc, CalendarState>(
              builder: (context, state) {
            if (state.allSchedules.isEmpty) {
              return const Center(child: Text("일정이 없습니다."));
            }

            final now = DateTime.now();
            final pastSchedules =
                state.allSchedules.where((s) => s.date.isBefore(now)).toList();

            final upcomingSchedules =
                state.allSchedules.where((s) => !s.date.isBefore(now)).toList();

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
