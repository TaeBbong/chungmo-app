/// Step 3:
/// Usecase
///
/// Pass data by running business logic using abstract repository

import 'package:injectable/injectable.dart';

import '../../core/base/base_usecase.dart';
import '../repositories/schedule_repository.dart';

@injectable
class BackfillVenuesUsecase implements NoParamUsecase<Future<void>> {
  final ScheduleRepository repository;

  BackfillVenuesUsecase(this.repository);

  @override
  Future<void> execute() {
    return repository.backfillVenues();
  }
}
