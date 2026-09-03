import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:chungmo/domain/entities/pay_statistics.dart';
import 'package:chungmo/domain/entities/relation.dart';
import 'package:chungmo/domain/entities/schedule.dart';
import 'package:chungmo/presentation/bloc/stats/stats_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../mocks/mocks.mocks.dart';

void main() {
  group('StatsCubit', () {
    late MockWatchAllSchedulesUsecase watch;
    late StreamController<List<Schedule>> schedules;
    late StatsCubit cubit;

    setUp(() {
      watch = MockWatchAllSchedulesUsecase();
      schedules = StreamController<List<Schedule>>();
      when(watch.execute()).thenAnswer((_) => schedules.stream);
      cubit = StatsCubit(watchAllSchedulesUsecase: watch);
    });

    tearDown(() async {
      await cubit.close();
      await schedules.close();
    });

    final tSchedule = Schedule(
      link: 'https://invitation.com',
      thumbnail: '',
      groom: '철수',
      bride: '영희',
      date: DateTime(2026, 10, 10),
      location: '서울',
      relation: Relation.friend,
      pay: 100000,
    );

    blocTest<StatsCubit, StatsState>(
      'aggregates every emission of the schedule stream',
      build: () => cubit,
      act: (cubit) {
        cubit.watchStatistics();
        schedules.add([tSchedule]);
        schedules.add([tSchedule, tSchedule.copyWith(link: 'b', pay: 50000)]);
      },
      expect: () => [
        StatsState(
          loaded: true,
          statistics: PayStatistics.fromSchedules([tSchedule]),
        ),
        const StatsState(
          loaded: true,
          statistics: PayStatistics(
            totalAmount: 150000,
            recordCount: 2,
            yearlyTotals: {2026: 150000},
            relationTotals: {Relation.friend: 150000},
          ),
        ),
      ],
    );

    blocTest<StatsCubit, StatsState>(
      'stays unloaded until the first list arrives',
      build: () => cubit,
      act: (cubit) => cubit.watchStatistics(),
      expect: () => const <StatsState>[],
      verify: (cubit) => expect(cubit.state.loaded, isFalse),
    );
  });
}
