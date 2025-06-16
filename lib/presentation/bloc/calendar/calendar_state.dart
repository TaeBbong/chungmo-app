import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/schedule.dart';

class CalendarState extends Equatable {
  final bool isLoading;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final List<Schedule> allSchedules;
  final Map<DateTime, List<Schedule>> currentMonthSchedules;

  const CalendarState({
    required this.isLoading,
    required this.focusedDay,
    required this.selectedDay,
    required this.allSchedules,
    required this.currentMonthSchedules,
  });

  factory CalendarState.initial() {
    return CalendarState(
      isLoading: false,
      focusedDay: DateTime.now(),
      selectedDay: DateTime.now(),
      allSchedules: const [],
      currentMonthSchedules: const {},
    );
  }

  CalendarState copyWith({
    bool? isLoading,
    DateTime? focusedDay,
    DateTime? selectedDay,
    List<Schedule>? allSchedules,
    Map<DateTime, List<Schedule>>? currentMonthSchedules,
  }) {
    return CalendarState(
      isLoading: isLoading ?? this.isLoading,
      focusedDay: focusedDay ?? this.focusedDay,
      selectedDay: selectedDay ?? this.selectedDay,
      allSchedules: allSchedules ?? this.allSchedules,
      currentMonthSchedules:
          currentMonthSchedules ?? this.currentMonthSchedules,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        focusedDay,
        selectedDay,
        const DeepCollectionEquality().hash(allSchedules),
        const DeepCollectionEquality().hash(currentMonthSchedules),
      ];

  @override
  bool get stringify => true;
}
