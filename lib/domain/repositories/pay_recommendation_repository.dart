/// Step 2:
/// Abstract Repository
///
/// Declare features as methods for each business logic

import '../entities/pay_recommendation.dart';
import '../entities/schedule.dart';

abstract class PayRecommendationRepository {
  /// Recommends a gift amount for [schedule], grounding the model in the
  /// user's own saved records and public statistics.
  ///
  /// Throws when the model is unreachable; callers decide whether to fall
  /// back to [PayRecommendation.fallback].
  Future<PayRecommendation> recommendPay(Schedule schedule);
}
