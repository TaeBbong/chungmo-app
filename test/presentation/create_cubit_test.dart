import 'package:bloc_test/bloc_test.dart';
import 'package:chungmo/domain/entities/schedule.dart';
import 'package:chungmo/presentation/bloc/create/create_cubit.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chungmo/domain/usecases/analyze_link_usecase.dart';
import 'package:chungmo/domain/usecases/save_schedule_usecase.dart';
import 'package:chungmo/domain/usecases/get_schedule_by_link_usecase.dart';
import 'package:chungmo/core/services/notification_service.dart';

import '../mocks/mocks.mocks.dart';

class MockAnalyzeLinkUsecase extends Mock implements AnalyzeLinkUsecase {}

class MockSaveScheduleUsecase extends Mock implements SaveScheduleUsecase {}

class MockNotificationService extends Mock implements NotificationService {}

class MockGetScheduleByLinkUsecase extends Mock
    implements GetScheduleByLinkUsecase {}

void main() {
  group('CreateCubit', () {
    late MockAnalyzeLinkUsecase analyze;
    late MockSaveScheduleUsecase save;
    late MockNotificationService notify;

    late MockCreateCubit cubit;

    setUp(() {
      analyze = MockAnalyzeLinkUsecase();
      save = MockSaveScheduleUsecase();
      notify = MockNotificationService();
      cubit = MockCreateCubit();
      // override cubit's dependencies
      cubit
        ..analyzeLinkUseCase = analyze
        ..saveScheduleUseCase = save
        ..notificationService = notify;
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

    blocTest<MockCreateCubit, CreateState>(
      'emits loading and success when analyze succeeds',
      build: () {
        when(analyze.execute(tUrl)).thenAnswer((_) async => tSchedule);
        when(save.execute(tSchedule)).thenAnswer((_) async => {});
        return cubit;
      },
      act: (cubit) => cubit.analyzeLink(tUrl),
      expect: () => [
        cubit.state.copyWith(isLoading: true, isError: false),
        cubit.state
            .copyWith(isLoading: false, schedule: tSchedule, isError: false),
      ],
    );
  });
}
