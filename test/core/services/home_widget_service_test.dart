import 'dart:async';

import 'package:chungmo/core/services/home_widget_service.dart';
import 'package:chungmo/core/utils/constants.dart';
import 'package:chungmo/domain/entities/schedule.dart';
import 'package:chungmo/domain/repositories/schedule_repository.dart';
import 'package:chungmo/domain/usecases/usecases.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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

/// Feeds [publish] through the real subscription path of [init].
class _FakeWatchAllSchedulesUsecase implements WatchAllSchedulesUsecase {
  final StreamController<List<Schedule>> controller =
      StreamController<List<Schedule>>.broadcast();

  @override
  ScheduleRepository get repository => throw UnimplementedError();

  @override
  Stream<List<Schedule>> execute() => controller.stream;
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
    late _FakeWatchAllSchedulesUsecase usecase;
    late HomeWidgetServiceImpl service;
    late List<MethodCall> calls;

    setUp(() {
      usecase = _FakeWatchAllSchedulesUsecase();
      service = HomeWidgetServiceImpl(usecase);
      calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('home_widget'),
              (MethodCall call) async {
        calls.add(call);
        return true;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('home_widget'), null);
      usecase.controller.close();
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

      expect(savedData(), {Constants.widgetHasScheduleKey: false});
      expect(calls.last.method, 'updateWidget');
    });

    test('init subscribes so a stream emission publishes', () async {
      await service.init();
      usecase.controller.add(const []);
      await usecase.controller.stream.first.timeout(const Duration(seconds: 1),
          onTimeout: () => const []);
      // Let the listener's async publish run to completion.
      await Future<void>.delayed(Duration.zero);

      expect(calls.any((MethodCall c) => c.method == 'updateWidget'), isTrue);
    });
  });
}
