/// Step 3:
/// Usecase
///
/// Pass data by running business logic using abstract repository

import 'package:injectable/injectable.dart';

import '../../core/base/base_usecase.dart';
import '../entities/schedule.dart';
import '../repositories/schedule_repository.dart';

@injectable
class SaveScheduleUsecase implements ParamUsecase<Schedule, Future<void>> {
  final ScheduleRepository repository;

  SaveScheduleUsecase(this.repository);

  @override
  Future<void> execute(Schedule schedule) {
    return repository.saveSchedule(schedule);
  }
}
