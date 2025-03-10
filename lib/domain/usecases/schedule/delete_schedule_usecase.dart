import 'package:injectable/injectable.dart';

import '../../repositories/schedule_repository.dart';

@injectable
class DeleteScheduleUsecase {
  final ScheduleRepository repository;

  DeleteScheduleUsecase(this.repository);

  Future<void> execute(String link) {
    return repository.deleteSchedule(link);
  }
}
