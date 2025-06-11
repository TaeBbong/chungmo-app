import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/usecases/usecases.dart';
import '../../domain/entities/schedule.dart';
import '../di/di.dart';
import '../utils/string_extension.dart';

/// Abstract class for NotificationService
///
/// 1. NotificationService gets permission(ALARM) from user.
///
/// 2. NotificationService adds, cancels local notification schedule for registered Schedules.
abstract class NotificationService {
  FlutterLocalNotificationsPlugin getLocalNotificationPlugin();
  Future<void> getPermissions();
  Future<void> init();
  Future<void> onDidReceiveNotificationResponse({required String link});
  Future<void> checkPreviousDayForNotify({required Schedule schedule});
  Future<void> addNotifySchedule({
    required int id,
    required String appName,
    required String title,
    required tz.TZDateTime scheduleDate,
    required String payload,
  });
  Future<void> cancelNotifySchedule({required String link});
  Future<void> checkScheduledNotifications();
  Future<void> addTestNotifySchedule({required int id});
}

@LazySingleton(as: NotificationService)
class NotificationServiceImpl implements NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifyPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  FlutterLocalNotificationsPlugin getLocalNotificationPlugin() {
    return _localNotifyPlugin;
  }

  /// Get permissions from user when opens app.
  ///
  /// Called by main.dart
  @override
  Future<void> getPermissions() async {
    if (await Permission.notification.isDenied &&
        !await Permission.notification.isPermanentlyDenied) {
      await [Permission.notification, Permission.scheduleExactAlarm].request();
    }
  }

  /// Initialize notification plugin settings.
  ///
  /// Called by main.dart
  @override
  Future<void> init() async {
    AndroidInitializationSettings android =
        const AndroidInitializationSettings("@mipmap/ic_launcher");
    DarwinInitializationSettings ios = const DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );
    InitializationSettings settings =
        InitializationSettings(android: android, iOS: ios);
    await _localNotifyPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) async {
        if (details.payload != null) {
          onDidReceiveNotificationResponse(link: details.payload!);
        }
      },
    );
    tz.initializeTimeZones();
  }

  /// `onDidReceiveNotificationResponse` handles onClickNotification from foreground/background state.
  ///
  /// Callback function for plugin.initialize(onDidReceiveNotificationResponse: () {}).
  ///
  /// Finds `targetSchedule` by key `link`, then routes to `detail` page.
  /// If `targetSchedule` was not found by key `link`, routes to `create` page.
  @override
  Future<void> onDidReceiveNotificationResponse({required String link}) async {
    final GetScheduleByLinkUsecase getScheduleByLinkUsecase =
        getIt<GetScheduleByLinkUsecase>();
    final Schedule? targetSchedule =
        await getScheduleByLinkUsecase.execute(link);
    if (targetSchedule != null) {
      Get.toNamed('/');
      Get.toNamed('/detail', arguments: targetSchedule);
    } else {
      Get.toNamed('/');
    }
  }

  /// Add notification at calculated date(_timeZoneSetting).
  ///
  /// If calculated date is before now, doesn't make notification.
  /// If calculated date is now but time is over 11:00am, notify tomorrow 9:00am.
  /// If calculated date is after today, notify schedule's previous day 9:00am.
  ///
  /// Called by ScheduleRepository; when user create/edit schedule.
  @override
  Future<void> checkPreviousDayForNotify({
    required Schedule schedule,
  }) async {
    final int id = await schedule.link.hashUrl;
    String title = "내일 ${schedule.groom} & ${schedule.bride}님의 결혼식이 있습니다!";
    tz.TZDateTime scheduleDate =
        _timeZoneSetting(scheduleDate: schedule.date, hour: 9, minute: 0);

    final now = tz.TZDateTime.now(scheduleDate.location);
    final todayEleven = tz.TZDateTime(
        scheduleDate.location, now.year, now.month, now.day, 11, 0);

    if (scheduleDate.isAtSameMomentAs(todayEleven) &&
        now.isAfter(todayEleven)) {
      final DateTime tomorrow = DateTime.now().add(const Duration(days: 1));
      scheduleDate = tz.TZDateTime(scheduleDate.location, tomorrow.year,
          tomorrow.month, tomorrow.day, 9, 0);
      title = "오늘 ${schedule.groom} & ${schedule.bride}님의 결혼식이 있습니다!";
    } else if (scheduleDate.isBefore(todayEleven)) {
      return;
    }

    await addNotifySchedule(
      id: id,
      appName: '청모',
      title: title,
      scheduleDate: scheduleDate,
      payload: schedule.link,
    );
  }

  /// Add notification schedule.
  ///
  /// Called by notifyScheduleAtPreviousDay()
  @override
  Future<void> addNotifySchedule({
    required int id,
    required String appName,
    required String title,
    required tz.TZDateTime scheduleDate,
    required String payload,
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

    await _localNotifyPlugin.zonedSchedule(
      id,
      "청모",
      title,
      scheduleDate,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  /// Cancel notification schedule already added.
  ///
  /// Called by ScheduleRepository when user edit/delete schedule.
  @override
  Future<void> cancelNotifySchedule({required String link}) async {
    final int id = await link.hashUrl;
    await _localNotifyPlugin.cancel(id);
  }

  /// Calculate targetDate = scheduleDate - 1, so user can get notification on day before event.
  tz.TZDateTime _timeZoneSetting({
    required DateTime scheduleDate,
    required int hour,
    required int minute,
  }) {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    DateTime previousDay = scheduleDate.subtract(const Duration(days: 1));
    tz.TZDateTime target = tz.TZDateTime(tz.getLocation('Asia/Seoul'),
        previousDay.year, previousDay.month, previousDay.day, hour, minute);
    return target;
  }

  @override
  Future<void> checkScheduledNotifications() async {
    List<PendingNotificationRequest> pendingNotifications =
        await _localNotifyPlugin.pendingNotificationRequests();

    // ignore: avoid_print
    print("📢 Total Scheduled Notifications: ${pendingNotifications.length}");

    for (var notification in pendingNotifications) {
      // ignore: avoid_print
      print(
          "🔔 ID: ${notification.id}, Title: ${notification.title}, Body: ${notification.body}, Date: ${notification.payload}");
    }
  }

  @override
  Future<void> addTestNotifySchedule({required int id}) async {
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

    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    tz.TZDateTime target = tz.TZDateTime.now(tz.getLocation('Asia/Seoul'))
        .add(const Duration(minutes: 2));
    await _localNotifyPlugin.zonedSchedule(
      id,
      "청모",
      "test notify $id",
      target,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: "https://naver.com",
    );
  }
}
