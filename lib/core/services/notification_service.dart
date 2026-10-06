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

  /// When a reminder lands, Korean time. One place, because two moments
  /// are derived from it.
  static const int _reminderHour = 9;

  /// The timezone database is process-global; prepare it once rather than
  /// on every date we build.
  static bool _timeZonesReady = false;

  final NowIn _now;

  /// The shipping constructor; injectable builds this one.
  NotificationServiceImpl() : _now = tz.TZDateTime.now;

  /// Replaces the clock, so the branches below — which all turn on what
  /// time it is — can be driven instead of waited for.
  @visibleForTesting
  NotificationServiceImpl.withClock(NowIn now) : _now = now;

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
    _ensureTimeZones();
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
    _ensureTimeZones();
    // Re-express the wedding in Seoul rather than reading its fields as
    // Seoul: `ScheduleMapper.toEntity` hands back the right *instant* in the
    // device's own zone, so on a phone outside Korea the fields say 04:30
    // for a 13:30 ceremony. Converting keeps the moment, and both slots are
    // then derived from the day it actually falls on there.
    final tz.TZDateTime wedding = _inSeoul(schedule.date);
    final tz.TZDateTime dayBefore =
        _morningOf(wedding.subtract(const Duration(days: 1)));
    final tz.TZDateTime onTheDay = _morningOf(wedding);
    final tz.TZDateTime now = _now(wedding.location);

    final String couple = '${schedule.groom} & ${schedule.bride}';
    final tz.TZDateTime target;
    final String title;
    if (dayBefore.isAfter(now)) {
      target = dayBefore;
      title = '내일 $couple님의 결혼식이 있습니다!';
    } else if (onTheDay.isAfter(now) && onTheDay.isBefore(wedding)) {
      // The day-before slot has gone — the invitation arrived late — but
      // the wedding has not. Guarded against the wedding itself, so a
      // ceremony starting before 09:00 is not 'reminded' about after it
      // has begun.
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

  /// Prepares the process-global timezone database, once.
  ///
  /// Separated out because it is a side effect: the date helpers below are
  /// pure, and this is the line that is not.
  void _ensureTimeZones() {
    if (_timeZonesReady) return;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    _timeZonesReady = true;
  }

  /// The same instant as [at], put on the Seoul clock.
  ///
  /// Converted, not reinterpreted: `ScheduleMapper.toEntity` returns the
  /// right instant expressed in the device's own zone, so reading its
  /// fields as Seoul would move a 13:30 ceremony to 04:30 on a phone
  /// outside Korea. Always Seoul because the wedding is in Korea, and that
  /// is the clock the reminder is about; a user abroad gets it in their own
  /// small hours, which is a separate question from this one.
  tz.TZDateTime _inSeoul(DateTime at) =>
      tz.TZDateTime.from(at, tz.getLocation('Asia/Seoul'));

  /// [day] at the reminder hour, Korean time.
  tz.TZDateTime _morningOf(DateTime day) => tz.TZDateTime(
      tz.getLocation('Asia/Seoul'),
      day.year,
      day.month,
      day.day,
      _reminderHour,
      0);

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

    _ensureTimeZones();
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
