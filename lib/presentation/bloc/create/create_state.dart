part of 'create_cubit.dart';

class CreateState extends Equatable {
  final bool isLoading;
  final bool isError;
  final Schedule? schedule;

  /// Saved schedules that have not happened yet, nearest first.
  final List<Schedule> upcomingSchedules;

  const CreateState({
    required this.isLoading,
    required this.isError,
    required this.schedule,
    required this.upcomingSchedules,
  });

  factory CreateState.initial() {
    return const CreateState(
      isLoading: false,
      isError: false,
      schedule: null,
      upcomingSchedules: [],
    );
  }

  CreateState copyWith({
    bool? isLoading,
    bool? isError,
    Schedule? schedule,
    List<Schedule>? upcomingSchedules,
  }) {
    return CreateState(
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
      schedule: schedule ?? this.schedule,
      upcomingSchedules: upcomingSchedules ?? this.upcomingSchedules,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isError,
        schedule,
        const DeepCollectionEquality().hash(upcomingSchedules),
      ];
}
