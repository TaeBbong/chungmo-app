import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/calendar_viewmodel.dart';
import '../theme/palette.dart';
import '../widgets/calendar_list_view.dart';
import '../widgets/calendar_view.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final CalendarController _controller = Get.put(CalendarController());
  bool _isCalendarView = true;

  @override
  void initState() {
    super.initState();
    _controller.getSchedulesForMonth(_controller.focusedDay.value);
    _controller.getAllSchedules();
  }

  @override
  void dispose() {
    Get.delete<CalendarController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '일정',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Palette.black),
        ),
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
      body: Obx(() {
        return _controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : _isCalendarView
                ? CalendarView()
                : CalendarListView();
      }),
    );
  }
}
