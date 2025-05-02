import 'package:injectable/injectable.dart';

import '../entities/schedule.dart';
import '../repositories/schedule_repository.dart';

@injectable
class ListSchedulesByDateUsecase {
  final ScheduleRepository repository;
  ListSchedulesByDateUsecase(this.repository);

  Future<Map<DateTime, List<Schedule>>> execute(DateTime date) {
    return repository.getSchedulesForMonth(date);
  }
}
