import 'package:injectable/injectable.dart';

import '../../core/base/base_usecase.dart';
import '../entities/schedule.dart';
import '../repositories/schedule_repository.dart';

@injectable
class GetScheduleByLinkUsecase
    implements ParamUsecase<String, Future<Schedule?>> {
  final ScheduleRepository repository;
  GetScheduleByLinkUsecase(this.repository);

  @override
  Future<Schedule?> execute(String link) {
    return repository.getScheduleByLink(link);
  }
}
