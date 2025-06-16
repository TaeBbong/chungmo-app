import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/di/di.dart';
import '../../../core/navigation/app_navigation.dart';
import '../../../core/services/notification_service.dart';
import '../../../domain/entities/schedule.dart';
import '../../../domain/usecases/usecases.dart';

part 'create_state.dart';

class CreateCubit extends Cubit<CreateState> {
  AnalyzeLinkUsecase analyzeLinkUseCase;
  SaveScheduleUsecase saveScheduleUseCase;
  NotificationService notificationService;

  CreateCubit({
    AnalyzeLinkUsecase? analyzeLinkUsecase,
    SaveScheduleUsecase? saveScheduleUsecase,
    NotificationService? notificationSvc,
  })  : analyzeLinkUseCase = analyzeLinkUsecase ?? getIt<AnalyzeLinkUsecase>(),
        saveScheduleUseCase =
            saveScheduleUsecase ?? getIt<SaveScheduleUsecase>(),
        notificationService = notificationSvc ?? getIt<NotificationService>(),
        super(CreateState.initial());

  Future<void> analyzeLink(String url) async {
    emit(state.copyWith(isLoading: true, isError: false));
    try {
      final scheduleFromRemote = await analyzeLinkUseCase.execute(url);
      await saveScheduleUseCase.execute(scheduleFromRemote);
      emit(state.copyWith(
          isLoading: false, schedule: scheduleFromRemote, isError: false));
    } catch (_) {
      emit(state.copyWith(isLoading: false, isError: true, schedule: null));
    }
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
