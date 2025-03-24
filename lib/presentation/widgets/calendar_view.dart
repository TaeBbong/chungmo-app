import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';

import '../controllers/calendar_viewmodel.dart';
import '../theme/palette.dart';
import 'schedule_list_tile.dart';

class CalendarView extends StatelessWidget {
  final CalendarController _controller = Get.find<CalendarController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final normalizedSelectedDay = DateTime(
          _controller.selectedDay.value.year,
          _controller.selectedDay.value.month,
          _controller.selectedDay.value.day);
      final eventCounts = _controller.schedulesWithDate.value ?? {};
      return Column(
        children: [
          TableCalendar(
            key: ValueKey(eventCounts.hashCode),
            locale: 'ko_KR',
            firstDay: DateTime(2000, 1, 1),
            lastDay: DateTime(2100, 12, 31),
            focusedDay: _controller.focusedDay.value,
            selectedDayPredicate: (day) =>
                isSameDay(_controller.selectedDay.value, day),
            onDaySelected: (selectedDay, focusedDay) {
              _controller.onDaySelected(selectedDay, focusedDay);
            },
            onPageChanged: (focusedDay) {
              _controller.onPageChanged(focusedDay);
              _controller.getSchedulesForMonth(focusedDay);
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
