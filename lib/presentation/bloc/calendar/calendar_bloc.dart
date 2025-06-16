import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/di.dart';
import '../../../domain/entities/schedule.dart';
import '../../../domain/usecases/usecases.dart';
import 'calendar_event.dart';
import 'calendar_state.dart';

class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final WatchAllSchedulesUsecase watchAllSchedulesUsecase =
      getIt<WatchAllSchedulesUsecase>();
  StreamSubscription<List<Schedule>>? _allSub;

  CalendarBloc() : super(CalendarState.initial()) {
    on<CalendarStarted>(_onStarted);
    on<DaySelected>(_onDaySelected);
    on<PageChanged>(_onPageChanged);
    on<SchedulesUpdated>(_onSchedulesUpdated);
  }

  void _onStarted(CalendarStarted event, Emitter<CalendarState> emit) {
    _allSub?.cancel();
    _allSub = watchAllSchedulesUsecase.execute().listen((list) {
      add(SchedulesUpdated(list));
    });
  }

  void _onSchedulesUpdated(
      SchedulesUpdated event, Emitter<CalendarState> emit) {
    final grouped = _groupSchedulesForMonth(state.focusedDay, event.schedules);
    emit(state.copyWith(
      allSchedules: event.schedules,
      currentMonthSchedules: grouped,
    ));
  }

  void _onDaySelected(DaySelected event, Emitter<CalendarState> emit) {
    emit(state.copyWith(
      focusedDay: event.selected,
      selectedDay: event.selected,
      currentMonthSchedules:
          _groupSchedulesForMonth(event.selected, state.allSchedules),
    ));
  }

  void _onPageChanged(PageChanged event, Emitter<CalendarState> emit) {
    emit(state.copyWith(
      focusedDay: event.focused,
      currentMonthSchedules:
          _groupSchedulesForMonth(event.focused, state.allSchedules),
    ));
  }

  Map<DateTime, List<Schedule>> _groupSchedulesForMonth(
      DateTime month, List<Schedule> schedules) {
    final Map<DateTime, List<Schedule>> grouped = {};
    for (final s in schedules) {
      if (s.date.year == month.year && s.date.month == month.month) {
        final key = DateTime(s.date.year, s.date.month, s.date.day);
        grouped.putIfAbsent(key, () => []).add(s);
      }
    }
    return grouped;
  }

  @override
  Future<void> close() {
    _allSub?.cancel();
    return super.close();
  }
}
