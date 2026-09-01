import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/di/di.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/date_extension.dart';
import '../../../domain/entities/schedule.dart';
import '../../../domain/entities/schedule_draft.dart';
import '../../../domain/usecases/usecases.dart';

part 'schedule_form_state.dart';

/// Backs the manual schedule form: builds a [Schedule] out of the form
/// fields (and an optional parse-fallback [ScheduleDraft]) and saves it.
class ScheduleFormCubit extends Cubit<ScheduleFormState> {
  SaveScheduleUsecase saveScheduleUseCase;
  AnalyticsService analytics;

  ScheduleFormCubit({
    SaveScheduleUsecase? saveScheduleUsecase,
    AnalyticsService? analyticsService,
  })  : saveScheduleUseCase =
            saveScheduleUsecase ?? getIt<SaveScheduleUsecase>(),
        analytics = analyticsService ?? getIt<AnalyticsService>(),
        super(const ScheduleFormState(status: ScheduleFormStatus.idle));

  Future<void> save({
    ScheduleDraft? draft,
    required String groom,
    required String bride,
    required DateTime date,
    required String location,
  }) async {
    if (state.status == ScheduleFormStatus.saving) return;
    emit(const ScheduleFormState(status: ScheduleFormStatus.saving));

    final Schedule schedule = Schedule(
      // Parse fallbacks keep their content-addressed link; blank entries
      // get a unique synthetic one, since the link is the schedule's key.
      link: (draft != null && draft.link.isNotEmpty)
          ? draft.link
          : 'manual://${DateTime.now().millisecondsSinceEpoch}',
      thumbnail: (draft != null && draft.thumbnail.isNotEmpty)
          ? draft.thumbnail
          : Constants.defaultThumbnail,
      groom: groom.trim(),
      bride: bride.trim(),
      date: date,
      location: location.trim(),
      groomAccounts: draft?.groomAccounts ?? const [],
      brideAccounts: draft?.brideAccounts ?? const [],
    );

    try {
      await saveScheduleUseCase.execute(schedule);
    } catch (error, stack) {
      analytics.recordError(error, stack,
          reason: AnalyticsEvents.manualScheduleSubmitted);
      emit(const ScheduleFormState(status: ScheduleFormStatus.failure));
      return;
    }

    analytics.logEvent(AnalyticsEvents.manualScheduleSubmitted, parameters: {
      AnalyticsParams.source: draft != null ? 'fallback' : 'blank',
    });
    analytics.logEvent(AnalyticsEvents.scheduleSaved, parameters: {
      AnalyticsParams.daysUntil: schedule.date.daysLeft,
      AnalyticsParams.hasAccounts: schedule.groomAccounts.isNotEmpty ||
          schedule.brideAccounts.isNotEmpty,
    });
    emit(const ScheduleFormState(status: ScheduleFormStatus.success));
  }
}
