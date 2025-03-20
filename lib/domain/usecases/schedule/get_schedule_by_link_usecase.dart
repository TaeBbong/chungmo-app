import 'package:injectable/injectable.dart';

import '../../entities/schedule.dart';
import '../../repositories/schedule_repository.dart';

@injectable
class GetScheduleByLinkUsecase {
  final ScheduleRepository repository;
  GetScheduleByLinkUsecase(this.repository);

  Future<Schedule?> execute(String link) {
    return repository.getScheduleByLink(link);
  }
}
