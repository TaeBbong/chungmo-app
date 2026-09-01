part of 'schedule_form_cubit.dart';

enum ScheduleFormStatus { idle, saving, success, failure }

class ScheduleFormState extends Equatable {
  final ScheduleFormStatus status;

  const ScheduleFormState({required this.status});

  bool get isSaving => status == ScheduleFormStatus.saving;

  @override
  List<Object?> get props => [status];
}
