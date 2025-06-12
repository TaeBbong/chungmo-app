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
          TableCalendar(
            key: ValueKey(eventCounts.hashCode),
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
                color: Palette.beige100,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Palette.beige,
                shape: BoxShape.circle,
              ),
              defaultTextStyle: const TextStyle(fontSize: 16),
              selectedTextStyle:
                  const TextStyle(fontSize: 16, color: Colors.black),
              todayTextStyle:
                  const TextStyle(fontSize: 16, color: Colors.black),
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
                              color: Palette.burgundy,
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
