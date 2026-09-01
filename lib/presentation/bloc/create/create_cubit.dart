import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/di/di.dart';
import '../../../core/utils/date_extension.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/services/notification_service.dart';
import '../../../domain/entities/invitation_image.dart';
import '../../../domain/entities/schedule.dart';
import '../../../domain/entities/schedule_draft.dart';
import '../../../domain/usecases/usecases.dart';

part 'create_state.dart';

class CreateCubit extends Cubit<CreateState> {
  AnalyzeLinkUsecase analyzeLinkUseCase;
  AnalyzeImageUsecase analyzeImageUseCase;
  AnalyzeTextUsecase analyzeTextUseCase;
  SaveScheduleUsecase saveScheduleUseCase;
  NotificationService notificationService;
  WatchAllSchedulesUsecase watchAllSchedulesUseCase;
  AnalyticsService analytics;

  StreamSubscription<List<Schedule>>? _schedulesSub;

  CreateCubit({
    AnalyzeLinkUsecase? analyzeLinkUsecase,
    AnalyzeImageUsecase? analyzeImageUsecase,
    AnalyzeTextUsecase? analyzeTextUsecase,
    SaveScheduleUsecase? saveScheduleUsecase,
    NotificationService? notificationSvc,
    WatchAllSchedulesUsecase? watchAllSchedulesUsecase,
    AnalyticsService? analyticsService,
  })  : analyzeLinkUseCase = analyzeLinkUsecase ?? getIt<AnalyzeLinkUsecase>(),
        analyzeImageUseCase =
            analyzeImageUsecase ?? getIt<AnalyzeImageUsecase>(),
        analyzeTextUseCase = analyzeTextUsecase ?? getIt<AnalyzeTextUsecase>(),
        saveScheduleUseCase =
            saveScheduleUsecase ?? getIt<SaveScheduleUsecase>(),
        notificationService = notificationSvc ?? getIt<NotificationService>(),
        watchAllSchedulesUseCase =
            watchAllSchedulesUsecase ?? getIt<WatchAllSchedulesUsecase>(),
        analytics = analyticsService ?? getIt<AnalyticsService>(),
        super(CreateState.initial());

  /// Feeds the home screen's preview of what is coming up.
  void watchUpcomingSchedules() {
    _schedulesSub?.cancel();
    _schedulesSub = watchAllSchedulesUseCase.execute().listen((schedules) {
      // By calendar day, matching the D-day badge and the calendar list.
      final List<Schedule> upcoming = schedules
          .where((schedule) => !schedule.date.isPastDay)
          .sorted((a, b) => a.date.compareTo(b.date));

      emit(state.copyWith(upcomingSchedules: upcoming));
    });
  }

  @override
  Future<void> close() {
    _schedulesSub?.cancel();
    return super.close();
  }

  Future<void> analyzeLink(String url, {String source = 'manual'}) async {
    analytics.logEvent(AnalyticsEvents.invitationLinkSubmitted,
        parameters: {AnalyticsParams.source: source});
    await _runParse(
        inputType: 'link', parse: () => analyzeLinkUseCase.execute(url));
  }

  /// Parses an invitation image (gallery pick or camera shot) through the
  /// same pipeline as [analyzeLink].
  Future<void> analyzeImage(InvitationImage image,
      {String source = 'gallery'}) async {
    analytics.logEvent(AnalyticsEvents.invitationImageSubmitted,
        parameters: {AnalyticsParams.source: source});
    await _runParse(
        inputType: 'image', parse: () => analyzeImageUseCase.execute(image));
  }

  /// Parses pasted invitation text (SMS, 카톡 message) through the same
  /// pipeline as [analyzeLink].
  Future<void> analyzeText(String text, {String source = 'manual'}) async {
    analytics.logEvent(AnalyticsEvents.invitationTextSubmitted,
        parameters: {AnalyticsParams.source: source});
    await _runParse(
        inputType: 'text', parse: () => analyzeTextUseCase.execute(text));
  }

  /// Shared parse pipeline: analytics, loading state, save on success.
  Future<void> _runParse({
    required String inputType,
    required Future<Schedule> Function() parse,
  }) async {
    emit(state.copyWith(isLoading: true, isError: false));
    analytics.logEvent(AnalyticsEvents.parseStarted,
        parameters: {AnalyticsParams.inputType: inputType});
    final Stopwatch stopwatch = Stopwatch()..start();
    try {
      final scheduleFromRemote = await parse();
      stopwatch.stop();
      final int accountCount = scheduleFromRemote.groomAccounts.length +
          scheduleFromRemote.brideAccounts.length;
      analytics.logEvent(AnalyticsEvents.parseSucceeded, parameters: {
        AnalyticsParams.inputType: inputType,
        AnalyticsParams.durationMs: stopwatch.elapsedMilliseconds,
        AnalyticsParams.hasAccounts: accountCount > 0,
        AnalyticsParams.accountCount: accountCount,
      });
      await saveScheduleUseCase.execute(scheduleFromRemote);
      analytics.logEvent(AnalyticsEvents.scheduleSaved, parameters: {
        AnalyticsParams.daysUntil: scheduleFromRemote.date.daysLeft,
        AnalyticsParams.hasAccounts: accountCount > 0,
      });
      // Built explicitly for symmetry with the error emit below: success
      // must not carry over a draft from an earlier incomplete parse.
      emit(CreateState(
        isLoading: false,
        isError: false,
        errorReason: null,
        draft: null,
        schedule: scheduleFromRemote,
        upcomingSchedules: state.upcomingSchedules,
      ));
    } catch (error, stack) {
      stopwatch.stop();
      final String reason = _classifyFailure(error);
      analytics.logEvent(AnalyticsEvents.parseFailed, parameters: {
        AnalyticsParams.inputType: inputType,
        AnalyticsParams.reason: reason,
        AnalyticsParams.durationMs: stopwatch.elapsedMilliseconds,
      });
      analytics.recordError(error, stack,
          reason: AnalyticsEvents.parseFailed,
          keys: {AnalyticsParams.reason: reason});
      // Built explicitly (not copyWith) so a draft from a previous
      // incomplete parse cannot leak into an unrelated failure.
      emit(CreateState(
        isLoading: false,
        isError: true,
        errorReason: reason,
        draft: error is IncompleteScheduleException ? error.draft : null,
        schedule: null,
        upcomingSchedules: state.upcomingSchedules,
      ));
    }
  }

  /// Best-effort classification of a parse failure for the `reason` parameter.
  String _classifyFailure(Object error) {
    // Before FormatException: an incomplete parse extends it, and the two
    // must stay distinguishable (draft offered vs nothing readable).
    if (error is IncompleteScheduleException) {
      return ParseFailureReason.incomplete;
    }
    if (error is TimeoutException) return ParseFailureReason.timeout;
    if (error is FormatException) return ParseFailureReason.format;
    return ParseFailureReason.unknown;
  }

  void resetState() {
    // The schedules stream is a broadcast without replay, so a plain
    // initial() would leave the home preview empty until the next DB write.
    emit(CreateState(
      isLoading: false,
      isError: false,
      errorReason: null,
      draft: null,
      schedule: null,
      upcomingSchedules: state.upcomingSchedules,
    ));
  }

  Future<void> checkIfNotification() async {
    final NotificationService notificationService =
        getIt<NotificationService>();
    final details = await notificationService
        .getLocalNotificationPlugin()
        .getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      analytics.logEvent(AnalyticsEvents.notificationOpened);
      final String link = details!.notificationResponse!.payload!;
      final getScheduleByLinkUsecase = getIt<GetScheduleByLinkUsecase>();
      final targetSchedule = await getScheduleByLinkUsecase.execute(link);

      if (targetSchedule != null) {
        navigatorKey.currentState
            ?.pushNamed('/detail', arguments: targetSchedule);
      }
    }
  }
}
