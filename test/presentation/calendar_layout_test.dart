import 'dart:async';

import 'package:chungmo/core/analytics/analytics_service.dart';
import 'package:chungmo/core/di/di.dart';
import 'package:chungmo/domain/entities/schedule.dart';
import 'package:chungmo/domain/usecases/usecases.dart';
import 'package:chungmo/presentation/bloc/calendar/calendar_bloc.dart';
import 'package:chungmo/presentation/bloc/calendar/calendar_event.dart';
import 'package:chungmo/presentation/pages/calendar_page.dart';
import 'package:chungmo/presentation/widgets/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mockito/mockito.dart';

import '../mocks/mocks.mocks.dart';

void main() {
  late MockWatchAllSchedulesUsecase watch;
  late StreamController<List<Schedule>> schedules;

  setUpAll(() => initializeDateFormatting('ko_KR'));

  setUp(() {
    watch = MockWatchAllSchedulesUsecase();
    schedules = StreamController<List<Schedule>>.broadcast();
    when(watch.execute()).thenAnswer((_) => schedules.stream);
    getIt.registerSingleton<WatchAllSchedulesUsecase>(watch);
    getIt.registerSingleton<AnalyticsService>(MockAnalyticsService());
  });

  tearDown(() async {
    await schedules.close();
    await getIt.reset();
  });

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: CalendarPage()));
    schedules.add(const []);
    await tester.pumpAndSettle();
  }

  /// Moves the calendar to a month that runs to six week rows.
  ///
  /// The grid is a row taller then, which is where a chrome height assumed
  /// 4dp short showed up — and only there, so a run in a five-row month
  /// passes either way. The context has to come from inside the page, below
  /// its BlocProvider.
  Future<void> showSixWeekMonth(WidgetTester tester) async {
    BlocProvider.of<CalendarBloc>(
      tester.element(find.byType(CalendarMonthView)),
      listen: false,
    ).add(PageChanged(DateTime(2026, 8, 1)));
    await tester.pumpAndSettle();
  }

  testWidgets('stacks the month over the day on a phone', (tester) async {
    await pumpAt(tester, const Size(390, 844));

    expect(find.byType(CalendarView), findsOneWidget);
    expect(find.byType(CalendarSplitView), findsNothing);
  });

  testWidgets('keeps one pane on a medium window', (tester) async {
    // 600-840 is wide enough to cap the body but not to split it.
    await pumpAt(tester, const Size(700, 1000));

    expect(find.byType(CalendarView), findsOneWidget);
    expect(find.byType(CalendarSplitView), findsNothing);
  });

  testWidgets('splits the month and the day on a tablet', (tester) async {
    await pumpAt(tester, const Size(1024, 1366));

    expect(find.byType(CalendarSplitView), findsOneWidget);
    expect(find.byType(CalendarMonthView), findsOneWidget);
    expect(find.byType(CalendarDayView), findsOneWidget);
    // The pane would otherwise sit blank with no explanation.
    expect(find.text('이 날에는 일정이 없습니다.'), findsOneWidget);
  });

  testWidgets('does not mistake a landscape phone for a tablet',
      (tester) async {
    // 844dp wide clears Material's expanded width class on its own, but a
    // phone on its side has nowhere to put a second pane.
    await pumpAt(tester, const Size(844, 390));

    expect(find.byType(CalendarSplitView), findsNothing);
    expect(find.byType(CalendarView), findsOneWidget);
  });

  testWidgets('survives a landscape phone without overflowing', (tester) async {
    // Landscape is enabled on every platform the app ships to, and a short
    // viewport is where a stacked month runs out of room. An overflow here
    // fails the test through the framework's own error reporting.
    await pumpAt(tester, const Size(844, 390));

    expect(tester.takeException(), isNull);
  });

  testWidgets('fits a six-week month on a phone', (tester) async {
    await pumpAt(tester, const Size(390, 844));

    await showSixWeekMonth(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('fits a six-week month on a single-pane tablet', (tester) async {
    // An iPad 10.2 in portrait: 810dp is under the two-pane width, so the
    // month is bounded by the stacked layout rather than filling a pane.
    await pumpAt(tester, const Size(810, 1080));

    await showSixWeekMonth(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('fills the second pane with the selected day\'s schedules',
      (tester) async {
    await pumpAt(tester, const Size(1024, 1366));
    schedules.add([
      Schedule(
        link: 'https://invite.test/a',
        thumbnail: '',
        groom: '김민준',
        bride: '이서연',
        date: DateTime.now().add(const Duration(days: 1)),
        location: '라온컨벤션 3층 그랜드홀',
        venue: '라온컨벤션',
        groomAccounts: const [],
        brideAccounts: const [],
      ),
    ]);
    await tester.pumpAndSettle();
    BlocProvider.of<CalendarBloc>(
      tester.element(find.byType(CalendarMonthView)),
      listen: false,
    ).add(DaySelected(DateTime.now().add(const Duration(days: 1)),
        DateTime.now().add(const Duration(days: 1))));
    await tester.pumpAndSettle();

    expect(find.text('김민준 & 이서연'), findsOneWidget);
    expect(find.text('이 날에는 일정이 없습니다.'), findsNothing);
  });

  testWidgets('grows the month rows when a pane gives it the height',
      (tester) async {
    await pumpAt(tester, const Size(390, 844));
    final phone = tester.getSize(find.byType(CalendarMonthView)).height;

    await pumpAt(tester, const Size(1024, 1366));
    final tablet = tester.getSize(find.byType(CalendarMonthView)).height;

    // Stacked, the month keeps its phone height and leaves the rest of a
    // tablet empty; in a pane it fills what it is given.
    expect(tablet, greaterThan(phone));
  });
}
