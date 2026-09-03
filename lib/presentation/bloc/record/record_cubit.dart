import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/di/di.dart';
import '../../../domain/entities/pay_recommendation.dart';
import '../../../domain/entities/relation.dart';
import '../../../domain/entities/schedule.dart';
import '../../../domain/usecases/usecases.dart';

part 'record_state.dart';

/// Backs the attendance/gift record page: fetches the AI amount
/// recommendation (degrading to the rule-based fallback) and saves the
/// record, so the flow is testable like every other cubit.
class RecordCubit extends Cubit<RecordState> {
  /// Firebase gives no deadline of its own; without one a hung request
  /// would pin the recommending state and disable the button forever.
  static const Duration recommendationTimeout = Duration(seconds: 20);

  final RecommendPayUsecase recommendPayUsecase;
  final EditScheduleUsecase editScheduleUsecase;
  final AnalyticsService analytics;

  RecordCubit({
    RecommendPayUsecase? recommendPayUsecase,
    EditScheduleUsecase? editScheduleUsecase,
    AnalyticsService? analyticsService,
  })  : recommendPayUsecase =
            recommendPayUsecase ?? getIt<RecommendPayUsecase>(),
        editScheduleUsecase =
            editScheduleUsecase ?? getIt<EditScheduleUsecase>(),
        analytics = analyticsService ?? getIt<AnalyticsService>(),
        super(const RecordState());

  /// Monotonic id of the newest recommendation request; a completed call
  /// whose id is stale (a grounding input changed, or a newer request
  /// started) has its result dropped.
  int _requestId = 0;

  /// Asks the model for an amount for [request]; failures and timeouts
  /// degrade to [PayRecommendation.fallback] instead of an error state.
  Future<void> recommend(Schedule request) async {
    analytics.logEvent(
      AnalyticsEvents.payRecommendationRequested,
      parameters: {AnalyticsParams.relation: request.relation.name},
    );
    final int requestId = ++_requestId;
    emit(state.copyWith(recommending: true));

    PayRecommendation result;
    bool fromFallback = false;
    try {
      result = await recommendPayUsecase
          .execute(request)
          .timeout(recommendationTimeout);
    } catch (error, stack) {
      // Contract violations (FormatException) and network/timeout failures
      // both fall back, but the cause still reaches Crashlytics — a rising
      // fallback rate is diagnosable.
      analytics.recordError(error, stack,
          reason: AnalyticsEvents.payRecommendationRequested);
      result = PayRecommendation.fallback(request.relation);
      fromFallback = true;
    }
    if (requestId != _requestId || isClosed) return;
    emit(state.copyWith(
      recommending: false,
      recommendation: result,
      recommendationFromFallback: fromFallback,
    ));
  }

  /// Drops the shown suggestion once a grounding input changes, so a card
  /// grounded in the old relation/attendance/note can't linger; an
  /// in-flight request's result is dropped too.
  void invalidateRecommendation() {
    _requestId++;
    emit(state.copyWith(clearRecommendation: true, recommending: false));
  }

  /// Logs the apply event and hands back the suggestion to fill the form
  /// with; null when none is shown.
  PayRecommendation? applyRecommendation(Relation relation) {
    final PayRecommendation? applied = state.recommendation;
    if (applied == null) return null;
    analytics.logEvent(
      AnalyticsEvents.payRecommendationApplied,
      parameters: {
        AnalyticsParams.relation: relation.name,
        AnalyticsParams.recommendationSource:
            state.recommendationFromFallback ? 'fallback' : 'model',
      },
    );
    return applied;
  }

  /// Persists the record; re-entrant taps while saving are ignored.
  Future<void> save(Schedule edited) async {
    if (state.isSaving) return;
    emit(state.copyWith(saveStatus: RecordSaveStatus.saving));

    try {
      await editScheduleUsecase.execute(edited);
    } catch (error, stack) {
      analytics.recordError(error, stack,
          reason: AnalyticsEvents.attendanceRecorded);
      emit(state.copyWith(saveStatus: RecordSaveStatus.failure));
      return;
    }

    analytics.logEvent(AnalyticsEvents.attendanceRecorded,
        parameters: {AnalyticsParams.status: edited.attendance.name});
    if (edited.pay > 0) {
      analytics.logEvent(AnalyticsEvents.giftRecorded,
          parameters: {AnalyticsParams.amountBucket: _amountBucket(edited.pay)});
    }
    emit(state.copyWith(saveStatus: RecordSaveStatus.success));
  }

  /// Maps a gift amount onto the `amount_bucket` analytics value.
  static String _amountBucket(int pay) {
    switch (pay) {
      case 50000:
        return '50k';
      case 100000:
        return '100k';
      case 200000:
        return '200k';
      case 300000:
        return '300k';
      default:
        return 'custom';
    }
  }
}
