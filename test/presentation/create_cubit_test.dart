import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:chungmo/core/analytics/analytics_events.dart';
import 'package:chungmo/core/analytics/noop_analytics_service.dart';
import 'package:chungmo/domain/entities/invitation_image.dart';
import 'package:chungmo/domain/entities/schedule.dart';
import 'package:chungmo/presentation/bloc/create/create_cubit.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/mocks.mocks.dart';

void main() {
  group('CreateCubit', () {
    late MockAnalyzeLinkUsecase analyze;
    late MockAnalyzeImageUsecase analyzeImage;
    late MockSaveScheduleUsecase save;
    late MockNotificationService notify;
    late MockWatchAllSchedulesUsecase watch;

    late CreateCubit cubit;

    setUp(() {
      analyze = MockAnalyzeLinkUsecase();
      analyzeImage = MockAnalyzeImageUsecase();
      save = MockSaveScheduleUsecase();
      notify = MockNotificationService();
      watch = MockWatchAllSchedulesUsecase();
      // Real cubit under test, with mocked dependencies injected.
      cubit = CreateCubit(
        analyzeLinkUsecase: analyze,
        analyzeImageUsecase: analyzeImage,
        saveScheduleUsecase: save,
        notificationSvc: notify,
        watchAllSchedulesUsecase: watch,
        analyticsService: const NoopAnalyticsService(),
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

    final tImage = InvitationImage(bytes: Uint8List.fromList([1, 2, 3]));
    final tImageSchedule = tSchedule.copyWith(link: 'image://12345');

    blocTest<CreateCubit, CreateState>(
      'emits loading and success when image analyze succeeds',
      build: () {
        when(analyzeImage.execute(tImage))
            .thenAnswer((_) async => tImageSchedule);
        when(save.execute(tImageSchedule)).thenAnswer((_) async {});
        return cubit;
      },
      act: (cubit) => cubit.analyzeImage(tImage),
      expect: () => [
        CreateState.initial().copyWith(isLoading: true, isError: false),
        CreateState.initial().copyWith(
            isLoading: false, schedule: tImageSchedule, isError: false),
      ],
      verify: (_) {
        verify(analyzeImage.execute(tImage)).called(1);
        verify(save.execute(tImageSchedule)).called(1);
      },
    );

    blocTest<CreateCubit, CreateState>(
      'emits loading and error when image analyze fails',
      build: () {
        when(analyzeImage.execute(tImage))
            .thenThrow(Exception('parse failed'));
        return cubit;
      },
      act: (cubit) => cubit.analyzeImage(tImage),
      expect: () => [
        CreateState.initial().copyWith(isLoading: true, isError: false),
        CreateState.initial().copyWith(
            isLoading: false,
            isError: true,
            errorReason: ParseFailureReason.unknown,
            schedule: null),
      ],
      verify: (_) {
        verifyNever(save.execute(any));
      },
    );

    blocTest<CreateCubit, CreateState>(
      'classifies a missing-datetime failure as format',
      build: () {
        when(analyzeImage.execute(tImage))
            .thenThrow(const FormatException('no datetime'));
        return cubit;
      },
      act: (cubit) => cubit.analyzeImage(tImage),
      expect: () => [
        CreateState.initial().copyWith(isLoading: true, isError: false),
        CreateState.initial().copyWith(
            isLoading: false,
            isError: true,
            errorReason: ParseFailureReason.format,
            schedule: null),
      ],
    );
  });
}
