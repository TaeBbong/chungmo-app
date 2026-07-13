import 'package:bloc_test/bloc_test.dart';
import 'package:chungmo/domain/entities/schedule.dart';
import 'package:chungmo/presentation/bloc/create/create_cubit.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/mocks.mocks.dart';

void main() {
  group('CreateCubit', () {
    late MockAnalyzeLinkUsecase analyze;
    late MockSaveScheduleUsecase save;
    late MockNotificationService notify;
    late MockWatchAllSchedulesUsecase watch;

    late CreateCubit cubit;

    setUp(() {
      analyze = MockAnalyzeLinkUsecase();
      save = MockSaveScheduleUsecase();
      notify = MockNotificationService();
      watch = MockWatchAllSchedulesUsecase();
      // Real cubit under test, with mocked dependencies injected.
      cubit = CreateCubit(
        analyzeLinkUsecase: analyze,
        saveScheduleUsecase: save,
        notificationSvc: notify,
        watchAllSchedulesUsecase: watch,
      );
    });

    tearDown(() {
      cubit.close();
    });

    const tUrl = 'https://test.com';
    final tSchedule = Schedule(
        link: tUrl,
        thumbnail: 'thumb',
        groom: 'g',
        bride: 'b',
        date: DateTime(2025, 1, 1),
        location: 'l');

    blocTest<CreateCubit, CreateState>(
      'emits loading and success when analyze succeeds',
      build: () {
        when(analyze.execute(tUrl)).thenAnswer((_) async => tSchedule);
        when(save.execute(tSchedule)).thenAnswer((_) async {});
        return cubit;
      },
      act: (cubit) => cubit.analyzeLink(tUrl),
      expect: () => [
        CreateState.initial().copyWith(isLoading: true, isError: false),
        CreateState.initial()
            .copyWith(isLoading: false, schedule: tSchedule, isError: false),
      ],
    );
  });
}
