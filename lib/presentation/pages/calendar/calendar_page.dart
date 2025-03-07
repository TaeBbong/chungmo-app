import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../controllers/calendar_viewmodel.dart';
import '../../theme/palette.dart';
import '../../widgets/schedule_list_tile.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final CalendarController _controller = Get.put(CalendarController());
  bool _isCalendarView = true;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _controller.getSchedulesForMonth(_focusedDay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("월간 스케줄"),
        actions: [
          IconButton(
            icon: Icon(_isCalendarView ? Icons.list : Icons.calendar_month),
            onPressed: () {
              setState(() {
                _isCalendarView = !_isCalendarView;
              });
            },
          ),
        ],
      ),
      body: Obx(() => _controller.isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : _isCalendarView
              ? _buildCalendarView()
              : _buildListView()),
    );
  }

  Widget _buildCalendarView() {
    final normalizedSelectedDay =
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    return Obx(() {
      final eventCounts = _controller.schedulesWithDate.value ?? {};
      return Column(
        children: [
          TableCalendar(
            locale: 'ko_KR',
            firstDay: DateTime(2000, 1, 1),
            lastDay: DateTime(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _focusedDay = selectedDay;
                _selectedDay = selectedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
                _controller.getSchedulesForMonth(focusedDay);
              });
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

  Widget _buildListView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  _focusedDay =
                      DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                  _controller.getSchedulesForMonth(_focusedDay);
                },
              ),
              Text(
                "${_focusedDay.year % 100}년 ${_focusedDay.month}월",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  _focusedDay =
                      DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                  _controller.getSchedulesForMonth(_focusedDay);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            final schedules = _controller.getAllSchedulesForMonth();
            if (schedules.isEmpty) {
              return const Center(child: Text("일정이 없습니다."));
            }
            return ListView.builder(
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final schedule = schedules[index];
                return ScheduleListTile(schedule: schedule);
              },
            );
          }),
        ),
      ],
    );
  }
}
