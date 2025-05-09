import 'package:injectable/injectable.dart';

import '../../core/base/base_usecase.dart';
import '../repositories/schedule_repository.dart';

@injectable
class DeleteScheduleUsecase implements ParamUsecase<String, Future<void>> {
  final ScheduleRepository repository;

  DeleteScheduleUsecase(this.repository);

  @override
  Future<void> execute(String link) {
    return repository.deleteSchedule(link);
  }
}
