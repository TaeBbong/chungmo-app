import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../controllers/calendar_viewmodel.dart';

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

  @override
  void initState() {
    super.initState();
    _controller.getSchedulesForMonth(_focusedDay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${_focusedDay.year % 100}년 ${_focusedDay.month}월"),
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

  // TODO: Calendar 모양 및 기능 미동작 수정
  Widget _buildCalendarView() {
    return Obx(() {
      final eventCounts = _controller.schedulesWithDate.value ?? {};
      return TableCalendar(
        firstDay: DateTime(2000, 1, 1),
        lastDay: DateTime(2100, 12, 31),
        focusedDay: _focusedDay,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _focusedDay = selectedDay;
          });
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
            _controller.getSchedulesForMonth(focusedDay);
          });
        },
        calendarFormat: CalendarFormat.month,
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, date, events) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // TODO: 각 날짜 클릭 시 일정 리스트 보여지게끔
                Text(date.day.toString()),
                if (eventCounts[date] != null && eventCounts[date]!.isNotEmpty)
                  Positioned(
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${eventCounts[date]!.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
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
                  _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                  _controller.getSchedulesForMonth(_focusedDay);
                },
              ),
              Text(
                "${_focusedDay.year % 100}년 ${_focusedDay.month}월",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
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
                // TODO: ListTile에 담을 정보 수정
                return ListTile(
                  title: Text('${schedule.groom} & ${schedule.bride}'),
                  subtitle: Text(schedule.date.toString()),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}