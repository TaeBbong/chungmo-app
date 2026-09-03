/// Step 6:
/// RepositoryImpl
///
/// Implementation of repository from domain layer
/// Implement each features of repository with data sources

import 'package:injectable/injectable.dart';

import '../../domain/entities/pay_recommendation.dart';
import '../../domain/entities/schedule.dart';
import '../../domain/repositories/pay_recommendation_repository.dart';
import '../mapper/schedule_mapper.dart';
import '../sources/local/schedule_local_source.dart';
import '../sources/remote/pay_recommendation_source.dart';

/// Implementation class for `PayRecommendationRepository`
@LazySingleton(as: PayRecommendationRepository)
class PayRecommendationRepositoryImpl implements PayRecommendationRepository {
  final PayRecommendationSource recommendationSource;
  final ScheduleLocalSource localSource;

  PayRecommendationRepositoryImpl(this.recommendationSource, this.localSource);

  @override
  Future<PayRecommendation> recommendPay(Schedule schedule) async {
    // The user's saved records become the personal half of the grounding
    // context; the source pairs them with public statistics.
    final history = await localSource.getAllSchedulesOnce();
    return recommendationSource.fetchRecommendation(
      target: schedule,
      history: history.map(ScheduleMapper.toEntity).toList(),
    );
  }
}
