import 'package:injectable/injectable.dart';

import '../../core/base/base_usecase.dart';
import '../entities/schedule.dart';
import '../repositories/schedule_repository.dart';

@injectable
class WatchSchedulesForMonthUsecase
    implements ParamUsecase<DateTime, Stream<Map<DateTime, List<Schedule>>>> {
  final ScheduleRepository repository;
  WatchSchedulesForMonthUsecase(this.repository);

  @override
  Stream<Map<DateTime, List<Schedule>>> execute(DateTime date) =>
      repository.getSchedulesForMonth(date);
}
