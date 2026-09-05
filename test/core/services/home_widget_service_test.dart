import 'dart:async';

import 'package:chungmo/core/services/home_widget_service.dart';
import 'package:chungmo/core/utils/constants.dart';
import 'package:chungmo/domain/entities/schedule.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../mocks/mocks.mocks.dart';

Schedule buildSchedule({
  required String link,
  required DateTime date,
  String groom = '김철수',
  String bride = '이영희',
  String location = '그랜드홀 3층',
}) {
  return Schedule(
    link: link,
    thumbnail: 'thumb',
    groom: groom,
    bride: bride,
    date: date,
    location: location,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeWidgetServiceImpl.pickUpcoming', () {
    final DateTime now = DateTime(2026, 9, 5, 15, 30);

    test('returns null when there is no schedule', () {
      expect(HomeWidgetServiceImpl.pickUpcoming(const [], now: now), isNull);
    });

    test('returns null when every schedule is past', () {
      final List<Schedule> schedules = [
        buildSchedule(link: 'a', date: DateTime(2026, 9, 4, 13)),
        buildSchedule(link: 'b', date: DateTime(2025, 12, 25, 11)),
      ];

      expect(HomeWidgetServiceImpl.pickUpcoming(schedules, now: now), isNull);
    });

    test('keeps a wedding held earlier today — its badge still reads D-DAY',
        () {
      final Schedule todayMorning =
          buildSchedule(link: 'a', date: DateTime(2026, 9, 5, 11));

      expect(
        HomeWidgetServiceImpl.pickUpcoming([todayMorning], now: now),
        todayMorning,
      );
    });

    test('picks the earliest upcoming among mixed past and future', () {
      final Schedule nearest =
          buildSchedule(link: 'near', date: DateTime(2026, 9, 12, 13));
      final List<Schedule> schedules = [
        buildSchedule(link: 'far', date: DateTime(2026, 11, 1, 12)),
        buildSchedule(link: 'past', date: DateTime(2026, 8, 30, 13)),
        nearest,
      ];

      expect(
        HomeWidgetServiceImpl.pickUpcoming(schedules, now: now),
        nearest,
      );
    });
  });

  group('HomeWidgetServiceImpl.formatCouple', () {
    test('joins both names', () {
      expect(
        HomeWidgetServiceImpl.formatCouple(
            buildSchedule(link: 'a', date: DateTime(2026, 10, 1))),
        '김철수 & 이영희',
      );
    });

    test('drops an empty name instead of leaving a dangling ampersand', () {
      expect(
        HomeWidgetServiceImpl.formatCouple(buildSchedule(
            link: 'a', date: DateTime(2026, 10, 1), bride: '')),
        '김철수',
      );
    });

    test('falls back to a generic label when both names are empty', () {
      expect(
        HomeWidgetServiceImpl.formatCouple(buildSchedule(
            link: 'a', date: DateTime(2026, 10, 1), groom: '', bride: '')),
        '결혼식',
      );
    });
  });

  group('HomeWidgetServiceImpl.hasRealThumbnail', () {
    test('accepts a genuine invitation thumbnail URL', () {
      expect(
        HomeWidgetServiceImpl.hasRealThumbnail('https://cdn.example.com/1.jpg'),
        isTrue,
      );
    });

    test('rejects the stock fallback illustration and non-URL values', () {
      expect(
        HomeWidgetServiceImpl.hasRealThumbnail(Constants.defaultThumbnail),
        isFalse,
      );
      expect(HomeWidgetServiceImpl.hasRealThumbnail(''), isFalse);
      expect(HomeWidgetServiceImpl.hasRealThumbnail('thumb'), isFalse);
    });
  });

  group('HomeWidgetServiceImpl.formatDateText', () {
    test('renders month, day, weekday and hour without the year', () {
      expect(
        HomeWidgetServiceImpl.formatDateText(DateTime(2026, 10, 25, 14, 0)),
        '10월 25일(일) 14시',
      );
    });

    test('appends minutes only when not on the hour', () {
      expect(
        HomeWidgetServiceImpl.formatDateText(DateTime(2026, 10, 24, 13, 30)),
        '10월 24일(토) 13시30분',
      );
    });
  });

  group('HomeWidgetServiceImpl.publish', () {
    late MockWatchAllSchedulesUsecase usecase;
    late StreamController<List<Schedule>> schedules;
    late HomeWidgetServiceImpl service;
    late List<MethodCall> calls;

    /// Completes once per updateWidget call — the marker that one publish
    /// finished. Broadcast so tests can wait for several publishes.
    late StreamController<void> updates;

    void mockChannel({Duration delay = Duration.zero}) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('home_widget'),
              (MethodCall call) async {
        calls.add(call);
        if (delay != Duration.zero) await Future<void>.delayed(delay);
        if (call.method == 'updateWidget') updates.add(null);
        return true;
      });
    }

    setUp(() {
      usecase = MockWatchAllSchedulesUsecase();
      schedules = StreamController<List<Schedule>>.broadcast();
      when(usecase.execute()).thenAnswer((_) => schedules.stream);
      service = HomeWidgetServiceImpl(usecase);
      calls = <MethodCall>[];
      updates = StreamController<void>.broadcast();
      mockChannel();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('home_widget'), null);
      schedules.close();
      updates.close();
    });

    Map<String, Object?> savedData() {
      return <String, Object?>{
        for (final MethodCall call in calls)
          if (call.method == 'saveWidgetData')
            (call.arguments as Map)['id'] as String:
                (call.arguments as Map)['data'],
      };
    }

    test('writes the nearest wedding and redraws the widget', () async {
      final DateTime date =
          DateTime.now().add(const Duration(days: 7)).copyWith(
                hour: 13,
                minute: 0,
                second: 0,
                millisecond: 0,
                microsecond: 0,
              );

      await service.publish([buildSchedule(link: 'a', date: date)]);

      final Map<String, Object?> data = savedData();
      expect(data[Constants.widgetHasScheduleKey], true);
      expect(data[Constants.widgetCoupleKey], '김철수 & 이영희');
      expect(data[Constants.widgetLocationKey], '그랜드홀 3층');
      expect(data[Constants.widgetDateMillisKey], date.millisecondsSinceEpoch);
      expect(calls.last.method, 'updateWidget');
    });

    test('publishes only the empty flag when nothing is upcoming', () async {
      await service.publish(const []);

      expect(savedData(), {
        Constants.widgetHasScheduleKey: false,
        // The background photo is cleared alongside so no stale image
        // outlives its schedule.
        Constants.widgetImageKey: null,
      });
      expect(calls.last.method, 'updateWidget');
    });

    test('clears the photo for the stock fallback thumbnail', () async {
      await service.publish([
        buildSchedule(
          link: 'a',
          date: DateTime.now().add(const Duration(days: 7)),
        ).copyWith(thumbnail: Constants.defaultThumbnail),
      ]);

      expect(savedData()[Constants.widgetImageKey], isNull);
    });

    test('clears the photo when the thumbnail fetch fails', () async {
      // The cached provider needs platform channels tests lack; a plain
      // NetworkImage against flutter_test's blocked HTTP (every request
      // returns 400) exercises the same fetch-failure fallback.
      service.thumbnailProvider = NetworkImage.new;
      await service.publish([
        buildSchedule(
          link: 'a',
          date: DateTime.now().add(const Duration(days: 7)),
        ).copyWith(thumbnail: 'https://cdn.example.com/unreachable.jpg'),
      ]);

      expect(savedData()[Constants.widgetImageKey], isNull);
      expect(calls.last.method, 'updateWidget');
    });

    test('init subscribes so a stream emission publishes', () async {
      final Future<void> published = updates.stream.first;
      await service.init();
      schedules.add(const []);
      await published.timeout(const Duration(seconds: 5));

      expect(calls.any((MethodCall c) => c.method == 'updateWidget'), isTrue);
    });

    test('serializes publishes so the last emission is the final state',
        () async {
      // A slowed channel makes an unserialized second publish interleave
      // with the first instead of waiting for it.
      mockChannel(delay: const Duration(milliseconds: 5));
      final Future<void> bothPublished = updates.stream.take(2).drain<void>();
      await service.init();

      final DateTime date = DateTime.now().add(const Duration(days: 7));
      schedules.add([buildSchedule(link: 'a', date: date)]);
      schedules.add([
        buildSchedule(link: 'b', date: date, groom: '박준호', bride: '최지우'),
      ]);
      await bothPublished.timeout(const Duration(seconds: 5));

      // The first publish finished (updateWidget) before the second wrote
      // anything, and the store ends on the last emission's data.
      final int firstUpdate =
          calls.indexWhere((MethodCall c) => c.method == 'updateWidget');
      final int firstSecondWrite = calls.indexWhere((MethodCall c) =>
          c.method == 'saveWidgetData' &&
          (c.arguments as Map)['data'] == '박준호 & 최지우');
      expect(firstSecondWrite, greaterThan(firstUpdate));
      expect(savedData()[Constants.widgetCoupleKey], '박준호 & 최지우');
    });
  });
}
