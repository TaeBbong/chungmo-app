import 'package:bloc_test/bloc_test.dart';
import 'package:chungmo/core/analytics/noop_analytics_service.dart';
import 'package:chungmo/core/utils/constants.dart';
import 'package:chungmo/domain/entities/account.dart';
import 'package:chungmo/domain/entities/schedule.dart';
import 'package:chungmo/domain/entities/schedule_draft.dart';
import 'package:chungmo/presentation/bloc/schedule_form/schedule_form_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../mocks/mocks.mocks.dart';

void main() {
  group('ScheduleFormCubit', () {
    late MockSaveScheduleUsecase save;
    late ScheduleFormCubit cubit;

    setUp(() {
      save = MockSaveScheduleUsecase();
      cubit = ScheduleFormCubit(
        saveScheduleUsecase: save,
        analyticsService: const NoopAnalyticsService(),
      );
    });

    tearDown(() {
      cubit.close();
    });

    final tDate = DateTime(2026, 10, 24, 13, 30);

    Schedule savedSchedule() =>
        verify(save.execute(captureAny)).captured.single as Schedule;

    blocTest<ScheduleFormCubit, ScheduleFormState>(
      'keys a blank entry with a synthetic manual link and default thumbnail',
      build: () {
        when(save.execute(any)).thenAnswer((_) async {});
        return cubit;
      },
      act: (cubit) => cubit.save(
          groom: ' 김민준 ', bride: '이서연', date: tDate, location: '그랜드홀 '),
      expect: () => [
        const ScheduleFormState(status: ScheduleFormStatus.saving),
        const ScheduleFormState(status: ScheduleFormStatus.success),
      ],
      verify: (_) {
        final Schedule saved = savedSchedule();
        expect(saved.link, startsWith('manual://'));
        expect(saved.thumbnail, Constants.defaultThumbnail);
        expect(saved.groom, '김민준');
        expect(saved.location, '그랜드홀');
      },
    );

    const tAccount =
        Account(bank: '국민', number: '123', holder: '김민준', relation: '신랑');
    const tDraft = ScheduleDraft(
      link: 'text://12345',
      thumbnail: 'https://thumb',
      groom: '김민준',
      bride: '이서연',
      location: '그랜드홀',
      groomAccounts: [tAccount],
    );

    blocTest<ScheduleFormCubit, ScheduleFormState>(
      'keeps the draft link, thumbnail and accounts on a fallback save',
      build: () {
        when(save.execute(any)).thenAnswer((_) async {});
        return cubit;
      },
      act: (cubit) => cubit.save(
          draft: tDraft,
          groom: tDraft.groom,
          bride: tDraft.bride,
          date: tDate,
          location: tDraft.location),
      expect: () => [
        const ScheduleFormState(status: ScheduleFormStatus.saving),
        const ScheduleFormState(status: ScheduleFormStatus.success),
      ],
      verify: (_) {
        final Schedule saved = savedSchedule();
        expect(saved.link, 'text://12345');
        expect(saved.thumbnail, 'https://thumb');
        expect(saved.groomAccounts, [tAccount]);
      },
    );

    blocTest<ScheduleFormCubit, ScheduleFormState>(
      'recovers into a failure state when saving throws',
      build: () {
        when(save.execute(any)).thenThrow(Exception('db down'));
        return cubit;
      },
      act: (cubit) =>
          cubit.save(groom: 'g', bride: 'b', date: tDate, location: 'l'),
      expect: () => [
        const ScheduleFormState(status: ScheduleFormStatus.saving),
        const ScheduleFormState(status: ScheduleFormStatus.failure),
      ],
    );
  });
}
