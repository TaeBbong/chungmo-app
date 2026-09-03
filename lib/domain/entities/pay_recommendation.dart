/// Step 1:
/// Pure Entity Model
///
/// Only getter, setter enabled
/// to passthrough data to presentation layer

import 'package:freezed_annotation/freezed_annotation.dart';

import 'relation.dart';

part 'pay_recommendation.freezed.dart';

/// A gift-amount (축의금) suggestion for one schedule.
///
/// Produced by the LLM grounded in the user's own records and public
/// survey statistics; [fallback] provides rule-based defaults when the
/// model call fails.
@freezed
abstract class PayRecommendation with _$PayRecommendation {
  const factory PayRecommendation({
    /// Recommended amount in KRW.
    required int amount,

    /// Reasonable lower bound in KRW.
    required int minAmount,

    /// Reasonable upper bound in KRW.
    required int maxAmount,

    /// One or two Korean sentences explaining the amount, citing the
    /// data it was grounded in.
    required String reason,
  }) = _PayRecommendation;

  /// Rule-based defaults per relation, used when the model is unreachable.
  /// Amounts follow common Korean etiquette (5/10/20만원 tiers).
  factory PayRecommendation.fallback(Relation relation) {
    return switch (relation) {
      Relation.family => const PayRecommendation(
          amount: 300000,
          minAmount: 200000,
          maxAmount: 500000,
          reason: '지금은 추천을 불러올 수 없어 일반적인 가족·친척 기준을 보여드려요.',
        ),
      Relation.friend => const PayRecommendation(
          amount: 100000,
          minAmount: 50000,
          maxAmount: 200000,
          reason: '지금은 추천을 불러올 수 없어 일반적인 친구 기준을 보여드려요.',
        ),
      Relation.coworker => const PayRecommendation(
          amount: 100000,
          minAmount: 50000,
          maxAmount: 150000,
          reason: '지금은 추천을 불러올 수 없어 일반적인 직장 기준을 보여드려요.',
        ),
      Relation.acquaintance || Relation.unset => const PayRecommendation(
          amount: 50000,
          minAmount: 50000,
          maxAmount: 100000,
          reason: '지금은 추천을 불러올 수 없어 일반적인 기준을 보여드려요.',
        ),
    };
  }
}
