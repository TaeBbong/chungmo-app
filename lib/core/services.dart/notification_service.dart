import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/schedule.dart';
import '../utils/url_hash.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifyPlugin =
      FlutterLocalNotificationsPlugin();

  /// Get permissions from user when opens app.
  ///
  /// Called by main.dart
  static Future<void> getPermissions() async {
    if (await Permission.notification.isDenied &&
        !await Permission.notification.isPermanentlyDenied) {
      await [Permission.notification].request();
    }
  }

  /// Initialize notification plugin settings.
  ///
  /// Called by main.dart
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
    tz.initializeTimeZones();
  }

  /// Add notification at calculated date(_timeZoneSetting).
  ///
  /// If calculated date is before now, doesn't make notification.
  /// If calculated date is now but time is over 11:00am, notify after 1 hour.
  ///
  /// Called by ScheduleRepository; when user create/edit schedule.
  static Future<void> notifyScheduleAtPreviousDay({
    required Schedule schedule,
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

    tz.TZDateTime scheduleDate =
        _timeZoneSetting(scheduleDate: schedule.date, hour: 11, minute: 0);

    final now = tz.TZDateTime.now(scheduleDate.location);
    final todayEleven = tz.TZDateTime(
        scheduleDate.location, now.year, now.month, now.day, 11, 0);

    if (scheduleDate.isAtSameMomentAs(todayEleven) &&
        now.isBefore(todayEleven)) {
      scheduleDate = tz.TZDateTime(
          scheduleDate.location, now.year, now.month, now.day, now.hour + 1, 0);
    } else if (scheduleDate.isBefore(todayEleven)) {
      return;
    }

    final int id = await UrlHash.hashUrlToInt(schedule.link);

    await _localNotifyPlugin.zonedSchedule(
      id,
      "청모",
      "내일 ${schedule.groom} & ${schedule.bride}님의 결혼식이 있습니다!",
      _timeZoneSetting(scheduleDate: schedule.date, hour: 11, minute: 0),
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload:
          _timeZoneSetting(scheduleDate: schedule.date, hour: 11, minute: 0)
              .toIso8601String(),
    );
  }

  /// Cancel notification schedule already added.
  ///
  /// Called by ScheduleRepository when user edit/delete schedule.
  static Future<void> cancelNotifySchedule({required String link}) async {
    final int id = await UrlHash.hashUrlToInt(link);
    await _localNotifyPlugin.cancel(id);
  }

  /// Calculate targetDate = scheduleDate - 1, so user can get notification on day before event.
  static tz.TZDateTime _timeZoneSetting({
    required String scheduleDate,
    required int hour,
    required int minute,
  }) {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    DateTime dateTime = DateTime.parse(scheduleDate);
    DateTime previousDay = dateTime.subtract(const Duration(days: 1));
    tz.TZDateTime target = tz.TZDateTime(tz.getLocation('Asia/Seoul'),
        previousDay.year, previousDay.month, previousDay.day, hour, minute);
    return target;
  }

  static Future<void> checkScheduledNotifications() async {
    List<PendingNotificationRequest> pendingNotifications =
        await _localNotifyPlugin.pendingNotificationRequests();

    print("📢 Total Scheduled Notifications: ${pendingNotifications.length}");

    for (var notification in pendingNotifications) {
      print(
          "🔔 ID: ${notification.id}, Title: ${notification.title}, Body: ${notification.body}, Date: ${notification.payload}");
    }
  }
}
