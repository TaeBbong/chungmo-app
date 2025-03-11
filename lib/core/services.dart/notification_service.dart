import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/entities/schedule.dart';
import '../../domain/usecases/schedule/list_schedules_usecase.dart';
import '../di/di.dart';

const String dailyCheckTask = "daily_schedule_check";

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifyPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> getPermissions() async {
    if (await Permission.notification.isDenied &&
        !await Permission.notification.isPermanentlyDenied) {
      await [Permission.notification].request();
    }
  }

  static Future<void> init() async {
    AndroidInitializationSettings android =
        const AndroidInitializationSettings("@mipmap/ic_launcher");
    DarwinInitializationSettings ios = const DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );
    InitializationSettings settings =
        InitializationSettings(android: android, iOS: ios);
    await _localNotifyPlugin.initialize(settings);
  }

  static void testNotify() async {
    NotificationDetails details = const NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      android: AndroidNotificationDetails(
        "1",
        "test",
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    await _localNotifyPlugin.show(1, "title", "body", details);
  }

  static Future<void> showNotify({
    required int id,
    required String title,
    required String body,
  }) async {
    NotificationDetails details = const NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      android: AndroidNotificationDetails(
        "1",
        "test",
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    await _localNotifyPlugin.show(id, title, body, details);
  }

  static Future<void> checkAndSendNotifications() async {
    final ListSchedulesUsecase listSchedulesUsecase =
        getIt<ListSchedulesUsecase>();

    final List<Schedule> schedules = await listSchedulesUsecase.execute();
    final DateTime now = DateTime.now();
    final DateTime tomorrow = now.add(const Duration(days: 1));

    for (var schedule in schedules) {
      final DateTime eventDate = DateTime.parse(schedule.date);
      if (eventDate.year == tomorrow.year &&
          eventDate.month == tomorrow.month &&
          eventDate.day == tomorrow.day) {
        await NotificationService.showNotify(
          id: 0,
          title: "청모",
          body: "내일 ${schedule.groom} & ${schedule.bride}님의 결혼식이 있습니다!",
        );
      }
    }
  }
}
