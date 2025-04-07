import 'package:injectable/injectable.dart';

import '../../entities/schedule.dart';
import '../../repositories/schedule_repository.dart';

@injectable
class CountSchedulesUsecase {
  final ScheduleRepository repository;
  CountSchedulesUsecase(this.repository);

  Future<int> execute() async {
    List<Schedule> schedules = await repository.getSchedules();
    return schedules.length;
  }
}
