import 'package:injectable/injectable.dart';

import '../../core/base/base_usecase.dart';
import '../entities/schedule.dart';
import '../repositories/schedule_repository.dart';

@injectable
class ListSchedulesByDateUsecase
    implements ParamUsecase<DateTime, Future<Map<DateTime, List<Schedule>>>> {
  final ScheduleRepository repository;
  ListSchedulesByDateUsecase(this.repository);

  @override
  Future<Map<DateTime, List<Schedule>>> execute(DateTime date) {
    return repository.getSchedulesForMonth(date);
  }
}
