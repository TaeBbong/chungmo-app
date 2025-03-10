import 'package:injectable/injectable.dart';

import '../../entities/schedule.dart';
import '../../repositories/schedule_repository.dart';

@injectable
class EditScheduleUsecase {
  final ScheduleRepository repository;

  EditScheduleUsecase(this.repository);

  Future<void> execute(Schedule schedule) {
    return repository.editSchedule(schedule);
  }
}
