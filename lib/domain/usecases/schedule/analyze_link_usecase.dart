import 'package:injectable/injectable.dart';

import '../../entities/schedule.dart';
import '../../repositories/schedule_repository.dart';

@injectable
class AnalyzeLinkUsecase {
  final ScheduleRepository repository;

  AnalyzeLinkUsecase(this.repository);

  Future<Schedule> execute(String link) {
    return repository.analyzeLink(link);
  }
}