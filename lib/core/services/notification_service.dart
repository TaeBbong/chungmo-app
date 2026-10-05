import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../navigation/app_navigation.dart';
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

/// Reads the current time in [location]. Defaults to the real clock.
typedef NowIn = tz.TZDateTime Function(tz.Location location);

@LazySingleton(as: NotificationService)
class NotificationServiceImpl implements NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifyPlugin =
      FlutterLocalNotificationsPlugin();

  final NowIn _now;

  /// The shipping constructor; injectable builds this one.
  NotificationServiceImpl() : _now = tz.TZDateTime.now;

  /// Fixes the clock, so the branches below — which all turn on what time
  /// it is — can be driven instead of waited for.
  @visibleForTesting
  NotificationServiceImpl.withClock(tz.TZDateTime fixedNow)
      : _now = ((_) => fixedNow);

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
      navigatorKey.currentState?.pushNamed('/');
      navigatorKey.currentState
          ?.pushNamed('/detail', arguments: targetSchedule);
    } else {
      navigatorKey.currentState?.pushNamed('/');
    }
  }

  /// Schedules the reminder for [schedule], at 09:00 Korean time.
  ///
  /// The morning before the wedding if that is still ahead; otherwise the
  /// morning of the wedding, worded for the day; otherwise nothing, because
  /// both moments have passed.
  ///
  /// This used to compare the slot against a fixed 11:00 rather than
  /// against now, which dropped the reminder for a wedding tomorrow at
  /// every hour of the day and left the same-day wording unreachable — a
  /// 09:00 slot can never be the same instant as 11:00 (#67).
  ///
  /// Called by ScheduleRepository; when user create/edit schedule.
  @override
  Future<void> checkPreviousDayForNotify({
    required Schedule schedule,
  }) async {
    final tz.TZDateTime dayBefore = _timeZoneSetting(
        scheduleDate: schedule.date, hour: 9, minute: 0, daysBefore: 1);
    final tz.TZDateTime onTheDay = _timeZoneSetting(
        scheduleDate: schedule.date, hour: 9, minute: 0, daysBefore: 0);
    final tz.TZDateTime now = _now(dayBefore.location);

    final String couple = '${schedule.groom} & ${schedule.bride}';
    final tz.TZDateTime target;
    final String title;
    if (dayBefore.isAfter(now)) {
      target = dayBefore;
      title = '내일 $couple님의 결혼식이 있습니다!';
    } else if (onTheDay.isAfter(now)) {
      // The day-before slot has gone — the invitation arrived late — but
      // the wedding has not.
      target = onTheDay;
      title = '오늘 $couple님의 결혼식이 있습니다!';
    } else {
      return;
    }

    await addNotifySchedule(
      id: await schedule.link.hashUrl,
      appName: '청모',
      title: title,
      scheduleDate: target,
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
      appName,
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

  /// The wedding's date shifted back [daysBefore] days, at [hour]:[minute]
  /// Korean time — where the reminder lands.
  ///
  /// Always Seoul: the wedding is in Korea, so 09:00 there is the morning
  /// the reminder is about. A user abroad gets it at their own small hours,
  /// which is a separate question from this one.
  tz.TZDateTime _timeZoneSetting({
    required DateTime scheduleDate,
    required int hour,
    required int minute,
    int daysBefore = 1,
  }) {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    final DateTime day = scheduleDate.subtract(Duration(days: daysBefore));
    return tz.TZDateTime(tz.getLocation('Asia/Seoul'), day.year, day.month,
        day.day, hour, minute);
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
