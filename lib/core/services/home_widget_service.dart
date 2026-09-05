import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:home_widget/home_widget.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/schedule.dart';
import '../../domain/usecases/usecases.dart';
import '../utils/constants.dart';

/// Abstract class for HomeWidgetService
///
/// 1. HomeWidgetService watches the schedule stream and mirrors the nearest
///    upcoming wedding into the platform shared store (App Group UserDefaults
///    on iOS, SharedPreferences on Android) via the `home_widget` plugin.
///
/// 2. The native widgets render from that store. Only static text and the
///    wedding epoch are written; the D-day itself is computed natively at
///    render time so it stays correct without the app running.
abstract class HomeWidgetService {
  Future<void> init();
}

@LazySingleton(as: HomeWidgetService)
class HomeWidgetServiceImpl implements HomeWidgetService {
  final WatchAllSchedulesUsecase watchAllSchedulesUsecase;
  HomeWidgetServiceImpl(this.watchAllSchedulesUsecase);

  /// iOS widget kind and Android provider, as the plugin addresses them.
  static const String _iOSWidgetName = 'ChungmoWidget';
  static const String _qualifiedAndroidName =
      'com.taebbong.chungmo.ChungmoWidgetProvider';

  /// Days of midnight update alarms kept armed on Android. The D-day rolls
  /// over at each midnight; iOS covers this with timeline entries instead.
  static const int _scheduledMidnights = 30;

  /// Decode width of the background photo saved for the widget. Bounds the
  /// PNG in the shared store — iOS widget extensions have a tight memory
  /// budget and RemoteViews bitmaps are size-capped too.
  static const int _photoWidth = 600;

  StreamSubscription<List<Schedule>>? _subscription;

  /// Subscribes to the schedule stream; every change re-publishes the widget.
  ///
  /// Called by main.dart
  @override
  Future<void> init() async {
    await HomeWidget.setAppGroupId(Constants.appGroupId);
    _subscription ??= watchAllSchedulesUsecase.execute().listen(publish);
  }

  /// Writes the nearest upcoming wedding to the shared store and asks the
  /// platform to redraw the widget.
  @visibleForTesting
  Future<void> publish(List<Schedule> schedules) async {
    final Schedule? next = pickUpcoming(schedules, now: DateTime.now());
    await HomeWidget.saveWidgetData<bool>(
        Constants.widgetHasScheduleKey, next != null);
    if (next != null) {
      await HomeWidget.saveWidgetData<String>(
          Constants.widgetCoupleKey, formatCouple(next));
      await HomeWidget.saveWidgetData<String>(
          Constants.widgetDateTextKey, formatDateText(next.date));
      await HomeWidget.saveWidgetData<String>(
          Constants.widgetLocationKey, next.location);
      await HomeWidget.saveWidgetData<int>(
          Constants.widgetDateMillisKey, next.date.millisecondsSinceEpoch);
    }
    await _savePhoto(next?.thumbnail);
    await HomeWidget.updateWidget(
      iOSName: _iOSWidgetName,
      qualifiedAndroidName: _qualifiedAndroidName,
    );
    await _scheduleAndroidMidnightUpdates(hasSchedule: next != null);
  }

  /// Saves the invitation thumbnail as the widget's background photo, or
  /// clears it (removing the stored file) so the native side falls back to
  /// the flat card. Cleared rather than kept on a fetch failure: a stale
  /// photo of the previous wedding is worse than no photo.
  Future<void> _savePhoto(String? thumbnail) async {
    if (thumbnail == null || !hasRealThumbnail(thumbnail)) {
      await HomeWidget.saveWidgetData<String>(Constants.widgetImageKey, null);
      return;
    }
    try {
      await HomeWidget.saveImage(
        Constants.widgetImageKey,
        ResizeImage(NetworkImage(thumbnail), width: _photoWidth),
      );
    } catch (_) {
      // Offline or a dead link.
      await HomeWidget.saveWidgetData<String>(Constants.widgetImageKey, null);
    }
  }

  /// Whether [thumbnail] is an actual invitation image. The parser falls
  /// back to [Constants.defaultThumbnail] (a stock illustration) — as a
  /// full-bleed widget background that reads as clutter, so only genuine
  /// thumbnails become photos.
  @visibleForTesting
  static bool hasRealThumbnail(String thumbnail) =>
      thumbnail.startsWith('http') && thumbnail != Constants.defaultThumbnail;

  /// Arms one update alarm per local midnight so the Android widget re-renders
  /// its D-day right when the calendar day changes. The plugin re-arms these
  /// after reboot and catches up on missed ones; `updatePeriodMillis` in the
  /// widget info XML backstops the window beyond the armed days. iOS needs
  /// none of this — the widget's own timeline carries a midnight entry.
  Future<void> _scheduleAndroidMidnightUpdates(
      {required bool hasSchedule}) async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (!hasSchedule) {
      // Nothing on the widget can change at midnight anymore.
      await HomeWidget.cancelScheduledWidgetUpdates(
          qualifiedAndroidName: _qualifiedAndroidName);
      return;
    }
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final List<DateTime> midnights = List<DateTime>.generate(
      _scheduledMidnights,
      (int i) => DateTime(today.year, today.month, today.day + i + 1),
    );
    await HomeWidget.scheduleWidgetUpdates(
      midnights,
      qualifiedAndroidName: _qualifiedAndroidName,
    );
  }

  /// The schedule the widget shows: the earliest one whose calendar day is
  /// today or later, so a wedding held earlier today still reads `D-DAY`.
  @visibleForTesting
  static Schedule? pickUpcoming(List<Schedule> schedules,
      {required DateTime now}) {
    final DateTime today = DateTime(now.year, now.month, now.day);
    return schedules
        .where((Schedule s) =>
            !DateTime(s.date.year, s.date.month, s.date.day).isBefore(today))
        .sortedBy((Schedule s) => s.date)
        .firstOrNull;
  }

  /// `'철수 & 영희'`; empty names drop out (text parsing can leave them
  /// blank), and with both blank falls back to a generic label.
  @visibleForTesting
  static String formatCouple(Schedule schedule) {
    final String names = <String>[schedule.groom, schedule.bride]
        .where((String name) => name.isNotEmpty)
        .join(' & ');
    return names.isEmpty ? '결혼식' : names;
  }

  /// `'10월 26일(일) 14시'` — [DateExtension.krDate] minus the year, which
  /// the small widget has no room for and, showing only an upcoming date,
  /// no need for either.
  @visibleForTesting
  static String formatDateText(DateTime date) {
    String text = '${date.month}월 ${date.day}일'
        '(${Constants.weekdays[date.weekday - 1]}) ${date.hour}시';
    if (date.minute != 0) text += '${date.minute}분';
    return text;
  }
}
