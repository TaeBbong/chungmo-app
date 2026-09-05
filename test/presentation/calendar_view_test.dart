import 'dart:async';

import 'package:chungmo/domain/entities/schedule.dart';
import 'package:chungmo/domain/usecases/usecases.dart';
import 'package:chungmo/core/di/di.dart';
import 'package:chungmo/presentation/bloc/calendar/calendar_bloc.dart';
import 'package:chungmo/presentation/bloc/calendar/calendar_event.dart';
import 'package:chungmo/presentation/widgets/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mockito/mockito.dart';
import 'package:table_calendar/table_calendar.dart';

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
  });

  tearDown(() {
    schedules.close();
    getIt.reset();
  });

  testWidgets('keeps the TableCalendar mounted across schedule emissions',
      (tester) async {
    final CalendarBloc bloc = CalendarBloc()..add(CalendarStarted());
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<CalendarBloc>.value(
            value: bloc,
            child: const CalendarView(),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    // byWidgetPredicate: TableCalendar is generic and byType would need the
    // exact inferred type argument to match.
    final Finder calendar =
        find.byWidgetPredicate((Widget w) => w is TableCalendar);
    final State before = tester.state(calendar);

    final DateTime now = DateTime.now();
    schedules.add([
      Schedule(
        link: 'a',
        thumbnail: '',
        groom: 'g',
        bride: 'b',
        date: DateTime(now.year, now.month, 15, 13),
        location: 'l',
      ),
    ]);
    await tester.pump();
    await tester.pump();

    // The regression this pins: a per-emission ValueKey used to remount the
    // calendar (killing its PageView mid-gesture); a plain rebuild must
    // reuse the same State.
    expect(identical(tester.state(calendar), before), isTrue);
  });
}
