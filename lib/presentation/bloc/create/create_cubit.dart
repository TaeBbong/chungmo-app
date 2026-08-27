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
import '../../../domain/usecases/usecases.dart';

part 'create_state.dart';

class CreateCubit extends Cubit<CreateState> {
  AnalyzeLinkUsecase analyzeLinkUseCase;
  AnalyzeImageUsecase analyzeImageUseCase;
  SaveScheduleUsecase saveScheduleUseCase;
  NotificationService notificationService;
  WatchAllSchedulesUsecase watchAllSchedulesUseCase;
  AnalyticsService analytics;

  StreamSubscription<List<Schedule>>? _schedulesSub;

  CreateCubit({
    AnalyzeLinkUsecase? analyzeLinkUsecase,
    AnalyzeImageUsecase? analyzeImageUsecase,
    SaveScheduleUsecase? saveScheduleUsecase,
    NotificationService? notificationSvc,
    WatchAllSchedulesUsecase? watchAllSchedulesUsecase,
    AnalyticsService? analyticsService,
  })  : analyzeLinkUseCase = analyzeLinkUsecase ?? getIt<AnalyzeLinkUsecase>(),
        analyzeImageUseCase =
            analyzeImageUsecase ?? getIt<AnalyzeImageUsecase>(),
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
      emit(state.copyWith(
          isLoading: false, schedule: scheduleFromRemote, isError: false));
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
      emit(state.copyWith(
          isLoading: false,
          isError: true,
          errorReason: reason,
          schedule: null));
    }
  }

  /// Best-effort classification of a parse failure for the `reason` parameter.
  String _classifyFailure(Object error) {
    if (error is TimeoutException) return ParseFailureReason.timeout;
    if (error is FormatException) return ParseFailureReason.format;
    return ParseFailureReason.unknown;
  }

  void resetState() {
    emit(CreateState.initial());
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
