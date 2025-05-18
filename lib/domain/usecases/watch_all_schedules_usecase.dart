import 'package:injectable/injectable.dart';

import '../../core/base/base_usecase.dart';
import '../entities/schedule.dart';
import '../repositories/schedule_repository.dart';

@injectable
class WatchAllSchedulesUsecase
    implements NoParamUsecase<Stream<List<Schedule>>> {
  final ScheduleRepository repository;
  WatchAllSchedulesUsecase(this.repository);

  @override
  Stream<List<Schedule>> execute() => repository.getAllSchedules();
}
