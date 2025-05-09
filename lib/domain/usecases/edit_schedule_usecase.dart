import 'package:injectable/injectable.dart';

import '../../core/base/base_usecase.dart';
import '../entities/schedule.dart';
import '../repositories/schedule_repository.dart';

@injectable
class EditScheduleUsecase implements ParamUsecase<Schedule, Future<void>> {
  final ScheduleRepository repository;

  EditScheduleUsecase(this.repository);

  @override
  Future<void> execute(Schedule schedule) {
    return repository.editSchedule(schedule);
  }
}
