/// Step 7:
/// Controllers(viewmodel)
///
/// Implementation of controllers that receive data from usecase,
/// control states for pages
import 'package:get/get.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/di/di.dart';

import '../../core/services/notification_service.dart';
import '../../domain/entities/schedule.dart';
import '../../domain/usecases/schedule/get_schedule_by_link_usecase.dart';
import '../../domain/usecases/schedule/analyze_link_usecase.dart';
import '../../domain/usecases/schedule/save_schedule_usecase.dart';

class CreateController extends GetxController {
  final AnalyzeLinkUsecase analyzeLinkUseCase = getIt<AnalyzeLinkUsecase>();
  final SaveScheduleUsecase saveScheduleUseCase = getIt<SaveScheduleUsecase>();
  final NotificationService notificationService = getIt<NotificationService>();

  /// `isLoading` checks if `analyzeLinkUseCase()` from remote source is running.
  var isLoading = false.obs;

  /// `isError` checks if  `analyzeLinkUseCase()` throws error while running.
  var isError = false.obs;

  /// `schedule` is entity that `analyzeLinkUseCase()` returns.
  var schedule = Rxn<Schedule>();

  /// `analyzeLink` executes `analyzeLinkUseCase`
  /// then executes `saveScheduleUseCase`.
  Future<void> analyzeLink(String url) async {
    isLoading(true);
    isError(false);
    try {
      schedule.value = await analyzeLinkUseCase.execute(url);
    } catch (e) {
      isError.value = true;
      schedule.value = null;
    }
    isLoading(false);

    await saveScheduleUseCase.execute(schedule.value!);
  }

  /// `resetState` resets states for next analyze.
  void resetState() {
    isLoading.value = false;
    isError.value = false;
    schedule.value = null;
  }

  /// `checkIfNotification` handles onClickNotification from terminated state.
  ///
  /// Detects NotificationAppLaunchDetails.response.payload, then routes to `detail` page.
  void checkIfNotification() async {
    final NotificationService notificationService =
        getIt<NotificationService>();
    FlutterLocalNotificationsPlugin notificationsPlugin =
        notificationService.getLocalNotificationPlugin();
    NotificationAppLaunchDetails? details =
        await notificationsPlugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      final String link = details!.notificationResponse!.payload!;
      final GetScheduleByLinkUsecase getScheduleByLinkUsecase =
          getIt<GetScheduleByLinkUsecase>();
      final Schedule targetSchedule =
          await getScheduleByLinkUsecase.execute(link);
      Get.toNamed('/detail', arguments: targetSchedule);
    }
  }
}
