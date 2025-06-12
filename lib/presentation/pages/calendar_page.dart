import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/calendar/calendar_bloc.dart';
import '../bloc/calendar/calendar_event.dart';
import '../bloc/calendar/calendar_state.dart';
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
  late final CalendarBloc bloc;
  bool _isCalendarView = true;

  @override
  void initState() {
    super.initState();
    bloc = CalendarBloc()..add(CalendarStarted());
  }

  @override
  void dispose() {
    bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CalendarBloc>.value(
      value: bloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '일정',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Palette.black),
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
        body:
            BlocBuilder<CalendarBloc, CalendarState>(builder: (context, state) {
          return state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _isCalendarView
                  ? const CalendarView()
                  : const CalendarListView();
        }),
      ),
    );
  }
}
