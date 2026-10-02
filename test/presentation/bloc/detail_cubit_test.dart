import 'package:chungmo/core/analytics/analytics_events.dart';
import 'package:chungmo/core/analytics/analytics_service.dart';
import 'package:chungmo/core/di/di.dart';
import 'package:chungmo/domain/entities/schedule.dart';
import 'package:chungmo/domain/usecases/usecases.dart';
import 'package:chungmo/presentation/bloc/detail/detail_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../mocks/mocks.mocks.dart';

Schedule _schedule({String venue = '라온컨벤션'}) => Schedule(
      link: 'https://invite.test/a',
      thumbnail: 'https://example.test/thumb.png',
      groom: '김민준',
      bride: '이서연',
      date: DateTime(2026, 10, 17, 13, 30),
      location: '라온컨벤션 3층 그랜드홀',
      venue: venue,
      groomAccounts: const [],
      brideAccounts: const [],
    );

void main() {
  late MockEditScheduleUsecase edit;
  late MockDeleteScheduleUsecase delete;
  late MockAnalyticsService analytics;
  late DetailCubit cubit;

  setUp(() {
    edit = MockEditScheduleUsecase();
    delete = MockDeleteScheduleUsecase();
    analytics = MockAnalyticsService();
    getIt.registerSingleton<EditScheduleUsecase>(edit);
    getIt.registerSingleton<DeleteScheduleUsecase>(delete);
    getIt.registerSingleton<AnalyticsService>(analytics);
    cubit = DetailCubit();
  });

  tearDown(() async {
    await cubit.close();
    await getIt.reset();
  });

  test('starts with no schedule', () {
    expect(cubit.state.schedule, isNull);
  });

  test('setSchedule puts the schedule in state', () {
    final schedule = _schedule();

    cubit.setSchedule(schedule);

    expect(cubit.state.schedule, schedule);
  });

  test('editSchedule shows the edit before the write completes', () async {
    when(edit.execute(any)).thenAnswer((_) async {});
    cubit.setSchedule(_schedule());
    final edited = _schedule(venue: '그랜드컨벤션');

    final pending = cubit.editSchedule(edited);

    // The detail page reflects the change straight away; the repository
    // call is what follows, not what gates it.
    expect(cubit.state.schedule, edited);
    await pending;
    verify(edit.execute(edited)).called(1);
  });

  test('deleteSchedule reports the deletion and removes it', () async {
    when(delete.execute(any)).thenAnswer((_) async {});

    await cubit.deleteSchedule('https://invite.test/a');

    verify(analytics.logEvent(AnalyticsEvents.scheduleDeleted)).called(1);
    verify(delete.execute('https://invite.test/a')).called(1);
  });
}
