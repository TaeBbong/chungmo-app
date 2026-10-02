import 'dart:async';

import 'package:chungmo/domain/entities/schedule.dart';
import 'package:chungmo/domain/usecases/watch_all_schedules_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../mocks/mocks.mocks.dart';

Schedule _schedule(String link) => Schedule(
      link: link,
      thumbnail: 'https://example.test/thumb.png',
      groom: '김민준',
      bride: '이서연',
      date: DateTime(2026, 10, 17, 13, 30),
      location: '라온컨벤션 3층 그랜드홀',
      venue: '라온컨벤션',
      groomAccounts: const [],
      brideAccounts: const [],
    );

void main() {
  late MockScheduleRepository repository;
  late WatchAllSchedulesUsecase usecase;
  late StreamController<List<Schedule>> controller;

  setUp(() {
    repository = MockScheduleRepository();
    controller = StreamController<List<Schedule>>.broadcast();
    when(repository.getAllSchedules()).thenAnswer((_) => controller.stream);
    usecase = WatchAllSchedulesUsecase(repository);
  });

  tearDown(() => controller.close());

  test('passes the repository stream through unchanged', () async {
    final emissions = <List<Schedule>>[];
    final sub = usecase.execute().listen(emissions.add);
    await pumpEventQueue();

    controller.add([_schedule('https://invite.test/a')]);
    controller.add(const []);
    await pumpEventQueue();

    expect(emissions.map((e) => e.length), [1, 0]);
    await sub.cancel();
  });

  test('forwards errors rather than swallowing them', () async {
    final errors = <Object>[];
    final sub = usecase.execute().listen(null, onError: errors.add);
    await pumpEventQueue();

    controller.addError(StateError('database gone'));
    await pumpEventQueue();

    expect(errors, hasLength(1));
    await sub.cancel();
  });

  test('asks the repository once per call, not once per listener', () {
    usecase.execute();

    verify(repository.getAllSchedules()).called(1);
  });
}
