import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:chungmo/core/analytics/noop_analytics_service.dart';
import 'package:chungmo/domain/entities/attendance.dart';
import 'package:chungmo/domain/entities/pay_recommendation.dart';
import 'package:chungmo/domain/entities/relation.dart';
import 'package:chungmo/domain/entities/schedule.dart';
import 'package:chungmo/presentation/bloc/record/record_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../mocks/mocks.mocks.dart';

void main() {
  group('RecordCubit', () {
    late MockRecommendPayUsecase recommend;
    late MockEditScheduleUsecase edit;
    late RecordCubit cubit;

    setUp(() {
      recommend = MockRecommendPayUsecase();
      edit = MockEditScheduleUsecase();
      cubit = RecordCubit(
        recommendPayUsecase: recommend,
        editScheduleUsecase: edit,
        analyticsService: const NoopAnalyticsService(),
      );
    });

    tearDown(() {
      cubit.close();
    });

    final tSchedule = Schedule(
      link: 'https://invitation.com',
      thumbnail: '',
      groom: '철수',
      bride: '영희',
      date: DateTime(2026, 10, 10),
      location: '서울 웨딩홀',
      attendance: Attendance.attending,
      relation: Relation.friend,
    );
    const tRecommendation = PayRecommendation(
        amount: 100000, minAmount: 50000, maxAmount: 200000, reason: '친구니까');

    blocTest<RecordCubit, RecordState>(
      'shows the model result after a successful recommendation',
      build: () {
        when(recommend.execute(any))
            .thenAnswer((_) async => tRecommendation);
        return cubit;
      },
      act: (cubit) => cubit.recommend(tSchedule),
      expect: () => [
        const RecordState(recommending: true),
        const RecordState(recommendation: tRecommendation),
      ],
      verify: (_) => verify(recommend.execute(tSchedule)).called(1),
    );

    blocTest<RecordCubit, RecordState>(
      'degrades a failed recommendation to the relation fallback',
      build: () {
        when(recommend.execute(any)).thenThrow(Exception('network'));
        return cubit;
      },
      act: (cubit) => cubit.recommend(tSchedule),
      expect: () => [
        const RecordState(recommending: true),
        RecordState(
          recommendation: PayRecommendation.fallback(Relation.friend),
          recommendationFromFallback: true,
        ),
      ],
    );

    late Completer<PayRecommendation> pending;
    blocTest<RecordCubit, RecordState>(
      'drops an in-flight result once the inputs are invalidated',
      build: () {
        pending = Completer<PayRecommendation>();
        when(recommend.execute(any)).thenAnswer((_) => pending.future);
        return cubit;
      },
      act: (cubit) async {
        final Future<void> request = cubit.recommend(tSchedule);
        cubit.invalidateRecommendation();
        // The result arrives after the inputs changed; it must not
        // resurrect a recommendation grounded in the old inputs.
        pending.complete(tRecommendation);
        await request;
      },
      expect: () => [
        const RecordState(recommending: true),
        const RecordState(),
      ],
    );

    blocTest<RecordCubit, RecordState>(
      'clears the shown recommendation on invalidation',
      build: () {
        when(recommend.execute(any))
            .thenAnswer((_) async => tRecommendation);
        return cubit;
      },
      act: (cubit) async {
        await cubit.recommend(tSchedule);
        cubit.invalidateRecommendation();
      },
      expect: () => [
        const RecordState(recommending: true),
        const RecordState(recommendation: tRecommendation),
        const RecordState(),
      ],
    );

    test('applyRecommendation hands back the shown suggestion', () async {
      when(recommend.execute(any)).thenAnswer((_) async => tRecommendation);
      await cubit.recommend(tSchedule);

      expect(cubit.applyRecommendation(Relation.friend), tRecommendation);
    });

    test('applyRecommendation returns null when nothing is shown', () {
      expect(cubit.applyRecommendation(Relation.friend), isNull);
    });

    blocTest<RecordCubit, RecordState>(
      'saves the record and reports success',
      build: () {
        when(edit.execute(any)).thenAnswer((_) async {});
        return cubit;
      },
      act: (cubit) => cubit.save(tSchedule),
      expect: () => [
        const RecordState(saveStatus: RecordSaveStatus.saving),
        const RecordState(saveStatus: RecordSaveStatus.success),
      ],
      verify: (_) => verify(edit.execute(tSchedule)).called(1),
    );

    blocTest<RecordCubit, RecordState>(
      'reports failure when the save throws',
      build: () {
        when(edit.execute(any)).thenThrow(Exception('db'));
        return cubit;
      },
      act: (cubit) => cubit.save(tSchedule),
      expect: () => [
        const RecordState(saveStatus: RecordSaveStatus.saving),
        const RecordState(saveStatus: RecordSaveStatus.failure),
      ],
    );

    blocTest<RecordCubit, RecordState>(
      'ignores a second save while one is in flight',
      build: () {
        final completer = Completer<void>();
        when(edit.execute(any)).thenAnswer((_) => completer.future);
        return cubit;
      },
      act: (cubit) {
        // ignore: unawaited_futures
        cubit.save(tSchedule);
        // ignore: unawaited_futures
        cubit.save(tSchedule);
      },
      expect: () => [
        const RecordState(saveStatus: RecordSaveStatus.saving),
      ],
      verify: (_) => verify(edit.execute(any)).called(1),
    );
  });
}
