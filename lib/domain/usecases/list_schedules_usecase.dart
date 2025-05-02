import 'package:injectable/injectable.dart';

import '../entities/schedule.dart';
import '../repositories/schedule_repository.dart';

@injectable
class ListSchedulesUsecase {
  final ScheduleRepository repository;
  ListSchedulesUsecase(this.repository);

  Future<List<Schedule>> execute() {
    return repository.getSchedules();
  }
}
