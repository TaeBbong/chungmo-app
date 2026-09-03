/// Step 5:
/// Data source
///
/// CRUD based data source implement with remote/local source

import '../../../domain/entities/pay_recommendation.dart';
import '../../../domain/entities/schedule.dart';

/// Produces a gift-amount recommendation for one schedule.
///
/// Works with domain types directly: the response is never persisted, so
/// there is no storage model to map through.
abstract class PayRecommendationSource {
  /// Recommends an amount for [target], grounded in [history] — the user's
  /// other saved schedules — and public statistics.
  Future<PayRecommendation> fetchRecommendation({
    required Schedule target,
    required List<Schedule> history,
  });
}
