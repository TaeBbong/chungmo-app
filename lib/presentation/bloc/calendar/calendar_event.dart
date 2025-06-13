import 'package:equatable/equatable.dart';
import '../../../domain/entities/schedule.dart';

abstract class CalendarEvent extends Equatable {
  const CalendarEvent();

  @override
  List<Object?> get props => [];
}

class CalendarStarted extends CalendarEvent {}

class DaySelected extends CalendarEvent {
  final DateTime selected;
  final DateTime focused;
  const DaySelected(this.selected, this.focused);

  @override
  List<Object?> get props => [selected, focused];
}

class PageChanged extends CalendarEvent {
  final DateTime focused;
  const PageChanged(this.focused);

  @override
  List<Object?> get props => [focused];
}

class SchedulesUpdated extends CalendarEvent {
  final List<Schedule> schedules;
  const SchedulesUpdated(this.schedules);

  @override
  List<Object?> get props => [schedules];
}
