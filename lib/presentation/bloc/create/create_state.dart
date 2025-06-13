part of 'create_cubit.dart';

class CreateState extends Equatable {
  final bool isLoading;
  final bool isError;
  final Schedule? schedule;

  const CreateState({
    required this.isLoading,
    required this.isError,
    required this.schedule,
  });

  factory CreateState.initial() {
    return const CreateState(
      isLoading: false,
      isError: false,
      schedule: null,
    );
  }

  CreateState copyWith({
    bool? isLoading,
    bool? isError,
    Schedule? schedule,
  }) {
    return CreateState(
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
      schedule: schedule ?? this.schedule,
    );
  }

  @override
  List<Object?> get props => [isLoading, isError, schedule];
}
