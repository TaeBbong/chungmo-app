/// Step 3:
/// Usecase
///
/// Pass data by running business logic using abstract repository

import 'package:injectable/injectable.dart';

import '../entities/schedule.dart';
import '../repositories/schedule_repository.dart';

@injectable
class AnalyzeLinkUsecase {
  final ScheduleRepository repository;

  AnalyzeLinkUsecase(this.repository);

  Future<Schedule> execute(String link) {
    return repository.analyzeLink(link);
  }
}
