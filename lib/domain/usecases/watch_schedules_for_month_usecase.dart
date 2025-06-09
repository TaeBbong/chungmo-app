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
  Stream<Map<DateTime, List<Schedule>>> execute(DateTime date) {
    return repository.getAllSchedules().map((list) {
      final grouped = <DateTime, List<Schedule>>{};
      for (final s in list) {
        if (s.date.year == date.year && s.date.month == date.month) {
          final key = DateTime(s.date.year, s.date.month, s.date.day);
          grouped.putIfAbsent(key, () => []).add(s);
        }
      }
      return grouped;
    });
  }
}
