import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';

import '../bloc/calendar/calendar_bloc.dart';
import '../bloc/calendar/calendar_event.dart';
import '../bloc/calendar/calendar_state.dart';
import '../theme/palette.dart';
import 'schedule_list_tile.dart';

class CalendarView extends StatelessWidget {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarBloc, CalendarState>(builder: (context, state) {
      final normalizedSelectedDay = DateTime(state.selectedDay.year,
          state.selectedDay.month, state.selectedDay.day);
      final eventCounts = state.currentMonthSchedules;
      return Column(
        children: [
          // No key on purpose: a per-emission ValueKey(eventCounts.hashCode)
          // used to force marker refreshes, but every bloc emission builds a
          // new map, so each month swipe/day tap REMOUNTED the calendar —
          // its PageView state died mid-gesture and the settle animation
          // snapped. Markers refresh through plain rebuilds anyway: the
          // markerBuilder closure captures the fresh map each build.
          TableCalendar(
            locale: 'ko_KR',
            firstDay: DateTime(2000, 1, 1),
            lastDay: DateTime(2100, 12, 31),
            focusedDay: state.focusedDay,
            selectedDayPredicate: (day) => isSameDay(state.selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              context
                  .read<CalendarBloc>()
                  .add(DaySelected(selectedDay, focusedDay));
            },
            onPageChanged: (focusedDay) {
              context.read<CalendarBloc>().add(PageChanged(focusedDay));
            },
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
            },
            daysOfWeekHeight: 40,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              todayDecoration: BoxDecoration(
                color: Palette.burgundy50,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Palette.burgundy,
                shape: BoxShape.circle,
              ),
              defaultTextStyle: const TextStyle(fontSize: 16),
              selectedTextStyle:
                  TextStyle(fontSize: 16, color: Palette.white),
              todayTextStyle:
                  TextStyle(fontSize: 16, color: Palette.burgundy),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, date, events) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(date.day.toString()),
                    const SizedBox(height: 4),
                  ],
                );
              },
              markerBuilder: (context, date, events) {
                final normalizedDate =
                    DateTime(date.year, date.month, date.day);
                final eventCount = eventCounts[normalizedDate]?.length ?? 0;
                // Burgundy dots vanish if they overlap the burgundy
                // selection circle, so selected days get a contrasting dot.
                final Color markerColor = isSameDay(state.selectedDay, date)
                    ? Palette.white
                    : Palette.burgundy;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: eventCount > 0
                      ? List.generate(
                          eventCount > 5 ? 5 : eventCount,
                          (index) => Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: markerColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : [const SizedBox(height: 6)],
                );
              },
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          eventCounts[normalizedSelectedDay] != null
              ? Expanded(
                  child: ListView.builder(
                      itemCount: eventCounts[normalizedSelectedDay]!.length,
                      itemBuilder: (context, index) {
                        final schedule =
                            eventCounts[normalizedSelectedDay]![index];
                        return ScheduleListTile(schedule: schedule);
                      }),
                )
              : Container(),
        ],
      );
    });
  }
}
