part of 'create_cubit.dart';

class CreateState extends Equatable {
  final bool isLoading;
  final bool isError;

  /// Why the last parse failed, one of [ParseFailureReason].
  /// Only meaningful while [isError] is true.
  final String? errorReason;

  /// Partial extraction kept from an incomplete parse, so the user can
  /// finish it by hand. Only meaningful while [isError] is true.
  final ScheduleDraft? draft;
  final Schedule? schedule;

  /// Saved schedules that have not happened yet, nearest first.
  final List<Schedule> upcomingSchedules;

  const CreateState({
    required this.isLoading,
    required this.isError,
    this.errorReason,
    this.draft,
    required this.schedule,
    required this.upcomingSchedules,
  });

  factory CreateState.initial() {
    return const CreateState(
      isLoading: false,
      isError: false,
      errorReason: null,
      draft: null,
      schedule: null,
      upcomingSchedules: [],
    );
  }

  CreateState copyWith({
    bool? isLoading,
    bool? isError,
    String? errorReason,
    ScheduleDraft? draft,
    Schedule? schedule,
    List<Schedule>? upcomingSchedules,
  }) {
    return CreateState(
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
      errorReason: errorReason ?? this.errorReason,
      draft: draft ?? this.draft,
      schedule: schedule ?? this.schedule,
      upcomingSchedules: upcomingSchedules ?? this.upcomingSchedules,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isError,
        errorReason,
        draft,
        schedule,
        const DeepCollectionEquality().hash(upcomingSchedules),
      ];
}
