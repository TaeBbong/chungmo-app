/// Step 3:
/// Usecase
///
/// Pass data by running business logic using abstract repository

import 'package:injectable/injectable.dart';

import '../../core/base/base_usecase.dart';
import '../entities/schedule.dart';
import '../repositories/schedule_repository.dart';

@injectable
class AnalyzeLinkUsecase implements ParamUsecase<String, Future<Schedule>> {
  final ScheduleRepository repository;

  AnalyzeLinkUsecase(this.repository);

  @override
  Future<Schedule> execute(String link) {
    return repository.analyzeLink(link);
  }
}
