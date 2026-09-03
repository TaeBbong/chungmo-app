part of 'record_cubit.dart';

enum RecordSaveStatus { idle, saving, success, failure }

class RecordState extends Equatable {
  final RecordSaveStatus saveStatus;

  /// Latest AI suggestion; null until requested or after invalidation.
  final PayRecommendation? recommendation;

  /// True while a recommendation request is in flight.
  final bool recommending;

  /// True when [recommendation] is the rule-based fallback, shown when the
  /// model call failed.
  final bool recommendationFromFallback;

  const RecordState({
    this.saveStatus = RecordSaveStatus.idle,
    this.recommendation,
    this.recommending = false,
    this.recommendationFromFallback = false,
  });

  bool get isSaving => saveStatus == RecordSaveStatus.saving;

  RecordState copyWith({
    RecordSaveStatus? saveStatus,
    PayRecommendation? recommendation,
    bool clearRecommendation = false,
    bool? recommending,
    bool? recommendationFromFallback,
  }) {
    return RecordState(
      saveStatus: saveStatus ?? this.saveStatus,
      recommendation: clearRecommendation
          ? null
          : (recommendation ?? this.recommendation),
      recommending: recommending ?? this.recommending,
      recommendationFromFallback:
          recommendationFromFallback ?? this.recommendationFromFallback,
    );
  }

  @override
  List<Object?> get props =>
      [saveStatus, recommendation, recommending, recommendationFromFallback];
}
