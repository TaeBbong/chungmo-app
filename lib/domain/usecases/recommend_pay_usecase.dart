/// Step 3:
/// Usecase
///
/// Pass data by running business logic using abstract repository

import 'package:injectable/injectable.dart';

import '../../core/base/base_usecase.dart';
import '../entities/pay_recommendation.dart';
import '../entities/schedule.dart';
import '../repositories/pay_recommendation_repository.dart';

@injectable
class RecommendPayUsecase
    implements ParamUsecase<Schedule, Future<PayRecommendation>> {
  final PayRecommendationRepository repository;

  RecommendPayUsecase(this.repository);

  @override
  Future<PayRecommendation> execute(Schedule schedule) {
    return repository.recommendPay(schedule);
  }
}
