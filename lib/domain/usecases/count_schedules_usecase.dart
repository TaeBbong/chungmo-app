import 'package:injectable/injectable.dart';

import '../../core/base/base_usecase.dart';
import '../entities/schedule.dart';
import '../repositories/schedule_repository.dart';

@injectable
class CountSchedulesUsecase implements NoParamUsecase<Future<int>> {
  final ScheduleRepository repository;
  CountSchedulesUsecase(this.repository);

  @override
  Future<int> execute() async {
    List<Schedule> schedules = await repository.getSchedules();
    return schedules.length;
  }
}
