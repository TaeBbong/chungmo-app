/// Step 3:
/// Usecase
///
/// Pass data by running business logic using abstract repository

import 'package:injectable/injectable.dart';

import '../entities/schedule.dart';
import '../repositories/schedule_repository.dart';

@injectable
class SaveScheduleUsecase {
  final ScheduleRepository repository;

  SaveScheduleUsecase(this.repository);

  Future<void> execute(Schedule schedule) {
    return repository.saveSchedule(schedule);
  }
}
