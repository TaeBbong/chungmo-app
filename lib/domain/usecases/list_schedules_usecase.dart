import 'package:injectable/injectable.dart';

import '../../core/base/base_usecase.dart';
import '../entities/schedule.dart';
import '../repositories/schedule_repository.dart';

@injectable
class ListSchedulesUsecase implements NoParamUsecase<Future<List<Schedule>>> {
  final ScheduleRepository repository;
  ListSchedulesUsecase(this.repository);

  @override
  Future<List<Schedule>> execute() {
    return repository.getSchedules();
  }
}
