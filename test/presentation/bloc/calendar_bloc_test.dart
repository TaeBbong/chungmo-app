import 'dart:async';

import 'package:chungmo/core/analytics/analytics_service.dart';
import 'package:chungmo/core/di/di.dart';
import 'package:chungmo/domain/entities/schedule.dart';
import 'package:chungmo/domain/usecases/usecases.dart';
import 'package:chungmo/presentation/bloc/calendar/calendar_bloc.dart';
import 'package:chungmo/presentation/bloc/calendar/calendar_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../mocks/mocks.mocks.dart';

Schedule _schedule(DateTime date, {String link = 'https://invite.test/a'}) =>
    Schedule(
      link: link,
      thumbnail: 'https://example.test/thumb.png',
      groom: '김민준',
      bride: '이서연',
      date: date,
      location: '라온컨벤션 3층 그랜드홀',
      venue: '라온컨벤션',
      groomAccounts: const [],
      brideAccounts: const [],
    );

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

void main() {
  late MockWatchAllSchedulesUsecase watch;
  late MockAnalyticsService analytics;
  late StreamController<List<Schedule>> schedules;
  late CalendarBloc bloc;

  setUp(() {
    watch = MockWatchAllSchedulesUsecase();
    analytics = MockAnalyticsService();
    schedules = StreamController<List<Schedule>>.broadcast();
    when(watch.execute()).thenAnswer((_) => schedules.stream);
    getIt.registerSingleton<WatchAllSchedulesUsecase>(watch);
    getIt.registerSingleton<AnalyticsService>(analytics);
    bloc = CalendarBloc();
  });

  tearDown(() async {
    await bloc.close();
    await schedules.close();
    await getIt.reset();
  });

  test('groups an emission into the focused month only', () async {
    final focused = bloc.state.focusedDay;
    final thisMonth = DateTime(focused.year, focused.month, 15, 13, 0);
    final nextMonth = DateTime(focused.year, focused.month + 1, 15, 13, 0);

    bloc.add(CalendarStarted());
    await pumpEventQueue();
    schedules.add([
      _schedule(thisMonth),
      _schedule(nextMonth, link: 'https://invite.test/b'),
    ]);
    await pumpEventQueue();

    expect(bloc.state.allSchedules, hasLength(2));
    expect(bloc.state.currentMonthSchedules.keys, [_day(thisMonth)]);
  });

  test('puts two weddings on the same day under one key', () async {
    final focused = bloc.state.focusedDay;
    final morning = DateTime(focused.year, focused.month, 15, 11, 0);
    final afternoon = DateTime(focused.year, focused.month, 15, 17, 0);

    bloc.add(CalendarStarted());
    await pumpEventQueue();
    schedules.add([
      _schedule(morning),
      _schedule(afternoon, link: 'https://invite.test/b'),
    ]);
    await pumpEventQueue();

    expect(bloc.state.currentMonthSchedules[_day(morning)], hasLength(2));
  });

  test('a page change regroups without needing a new emission', () async {
    final focused = bloc.state.focusedDay;
    final nextMonth = DateTime(focused.year, focused.month + 1, 15, 13, 0);

    bloc.add(CalendarStarted());
    await pumpEventQueue();
    schedules.add([_schedule(nextMonth)]);
    await pumpEventQueue();
    expect(bloc.state.currentMonthSchedules, isEmpty);

    bloc.add(PageChanged(nextMonth));
    await pumpEventQueue();

    // The list it regroups from is the one already in state; swiping a
    // month must not depend on the stream emitting again.
    expect(bloc.state.currentMonthSchedules.keys, [_day(nextMonth)]);
    expect(bloc.state.focusedDay, nextMonth);
  });

  test('selecting a day moves both the selection and the focus', () async {
    final focused = bloc.state.focusedDay;
    final target = DateTime(focused.year, focused.month, 15, 13, 0);

    bloc.add(CalendarStarted());
    await pumpEventQueue();
    schedules.add([_schedule(target)]);
    await pumpEventQueue();
    bloc.add(DaySelected(target, target));
    await pumpEventQueue();

    expect(bloc.state.selectedDay, target);
    expect(bloc.state.focusedDay, target);
    expect(bloc.state.currentMonthSchedules[_day(target)], hasLength(1));
  });

  test('a repeated start does not stack subscriptions', () async {
    // hasListener on a broadcast controller says nothing about how many
    // listeners there are, so count the live subscriptions directly: a
    // second start that forgot to cancel would leave two, and one emission
    // would become two identical rebuilds.
    var active = 0;
    when(watch.execute()).thenAnswer((_) => Stream<List<Schedule>>.multi((c) {
          active++;
          final sub = schedules.stream.listen(c.add);
          c.onCancel = () {
            active--;
            return sub.cancel();
          };
        }));

    bloc.add(CalendarStarted());
    await pumpEventQueue();
    bloc.add(CalendarStarted());
    await pumpEventQueue();

    expect(active, 1);
  });

  test('a stream error is reported, not thrown at the zone', () async {
    bloc.add(CalendarStarted());
    await pumpEventQueue();

    // Without an onError the failure escapes to platformDispatcher.onError,
    // which files a still-running app as a fatal crash.
    schedules.addError(StateError('database unavailable'));
    await pumpEventQueue();

    verify(analytics.recordError(any, any, reason: 'schedule_stream'))
        .called(1);
    expect(bloc.state.allSchedules, isEmpty);
  });

  test('closing cancels the subscription', () async {
    bloc.add(CalendarStarted());
    await pumpEventQueue();
    expect(schedules.hasListener, isTrue);

    await bloc.close();
    await pumpEventQueue();

    expect(schedules.hasListener, isFalse);
  });
}
