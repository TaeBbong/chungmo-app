import 'package:chungmo/data/mapper/schedule_mapper.dart';
import 'package:chungmo/data/models/schedule/schedule_model.dart';
import 'package:chungmo/data/repositories/schedule_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../mocks/mocks.mocks.dart'; // build_runner로 생성된 파일

void main() {
  late ScheduleRepositoryImpl repository;
  late MockScheduleRemoteSource mockRemoteSource;
  late MockScheduleLocalSource mockLocalSource;
  late MockNotificationService mockNotificationService;

  setUp(() {
    mockRemoteSource = MockScheduleRemoteSource();
    mockLocalSource = MockScheduleLocalSource();
    mockNotificationService = MockNotificationService();
    repository = ScheduleRepositoryImpl(
        mockRemoteSource, mockLocalSource, mockNotificationService);
  });

  const tUrl = "https://test.com";
  var tScheduleModel = ScheduleModel(
    link: tUrl,
    thumbnail: "https://test.com/thumbnail.jpg",
    groom: "John",
    bride: "Jane",
    date: DateTime(2024, 6, 10).toIso8601String(),
    location: "Seoul",
  );

  final today = DateTime.now();
  final yesterday = today.subtract(const Duration(days: 1));
  final tomorrow = today.add(const Duration(days: 1));
  final farFuture = today.add(const Duration(days: 365));

  final tSchedule = ScheduleMapper.toEntity(tScheduleModel);

  group('analyzeLink', () {
    test('should return Schedule when remote source call is successful',
        () async {
      // Given
      when(mockRemoteSource.fetchScheduleFromServer(any))
          .thenAnswer((_) async => tScheduleModel);

      // When
      final result = await repository.analyzeLink(tUrl);

      // Then
      expect(result, tSchedule);
      verify(mockRemoteSource.fetchScheduleFromServer(tUrl)).called(1);
    });

    test('should throw Exception when remote source fails', () async {
      // Given
      when(mockRemoteSource.fetchScheduleFromServer(any))
          .thenThrow(Exception("Server Error"));

      // When
      expect(() => repository.analyzeLink(tUrl), throwsException);

      // Then
      verify(mockRemoteSource.fetchScheduleFromServer(tUrl)).called(1);
    });
  });

  group('saveSchedule', () {
    test('should save schedule to local storage and trigger notification',
        () async {
      // Given
      when(mockLocalSource.saveSchedule(any)).thenAnswer((_) async => {});
      when(mockNotificationService.checkPreviousDayForNotify(
              schedule: anyNamed('schedule')))
          .thenAnswer((_) async => {});

      // When
      await repository.saveSchedule(tSchedule);

      // Then
      verify(mockLocalSource.saveSchedule(any)).called(1);
      verify(mockNotificationService.checkPreviousDayForNotify(
              schedule: anyNamed('schedule')))
          .called(1);
    });
  });

  group('getSchedules', () {
    test('should return list of schedules when local source is successful',
        () async {
      // Given
      when(mockLocalSource.getAllSchedules())
          .thenAnswer((_) async => [tScheduleModel]);

      // When
      final result = await repository.getSchedules();

      // Then
      expect(result, [tSchedule]);
      verify(mockLocalSource.getAllSchedules()).called(1);
    });
  });

  group('getSchedulesForMonth', () {
    final tDate = DateTime(2024, 6, 1);
    final tMap = {
      DateTime(2024, 6, 10): [tScheduleModel]
    };

    test('should return map of schedules grouped by date', () async {
      // Given
      when(mockLocalSource.getSchedulesForMonth(tDate))
          .thenAnswer((_) async => tMap);

      // When
      final result = await repository.getSchedulesForMonth(tDate);

      // Then
      expect(result.keys.first, tMap.keys.first);
      expect(result.values.first, [tSchedule]);
      verify(mockLocalSource.getSchedulesForMonth(tDate)).called(1);
    });
  });

  group('editSchedule - Notification Behavior', () {
    test('should NOT trigger notification if schedule date is in the past',
        () async {
      // Given
      final pastSchedule =
          tSchedule.copyWith(date: yesterday.toIso8601String());

      when(mockLocalSource.editSchedule(any)).thenAnswer((_) async => {});
      when(mockNotificationService.cancelNotifySchedule(link: anyNamed('link')))
          .thenAnswer((_) async => {});

      // When
      await repository.editSchedule(pastSchedule);

      // Then
      verify(mockLocalSource.editSchedule(any)).called(1);
      verify(mockNotificationService.cancelNotifySchedule(
              link: anyNamed('link')))
          .called(1);
      verifyNever(mockNotificationService.addNotifySchedule(
          id: anyNamed('id'),
          appName: anyNamed('appName'),
          title: anyNamed('title'),
          scheduleDate: anyNamed('scheduleDate')));
    });

    test('should NOT trigger notification if schedule date is today', () async {
      // Given
      final todaySchedule = tSchedule.copyWith(date: today.toIso8601String());

      when(mockLocalSource.editSchedule(any)).thenAnswer((_) async => {});
      when(mockNotificationService.cancelNotifySchedule(link: anyNamed('link')))
          .thenAnswer((_) async => {});

      // When
      await repository.editSchedule(todaySchedule);

      // Then
      verify(mockLocalSource.editSchedule(any)).called(1);
      verify(mockNotificationService.cancelNotifySchedule(
              link: anyNamed('link')))
          .called(1);
      verifyNever(mockNotificationService.addNotifySchedule(
          id: anyNamed('id'),
          appName: anyNamed('appName'),
          title: anyNamed('title'),
          scheduleDate: anyNamed('scheduleDate')));
    });

    test('should trigger notification if schedule date is tomorrow', () async {
      // Given
      final tomorrowSchedule =
          tSchedule.copyWith(date: tomorrow.toIso8601String());

      when(mockLocalSource.editSchedule(any)).thenAnswer((_) async => {});
      when(mockNotificationService.cancelNotifySchedule(link: anyNamed('link')))
          .thenAnswer((_) async => {});
      when(mockNotificationService.checkPreviousDayForNotify(
              schedule: anyNamed('schedule')))
          .thenAnswer((_) async => {});

      // When
      await repository.editSchedule(tomorrowSchedule);

      // Then
      verify(mockLocalSource.editSchedule(any)).called(1);
      verify(mockNotificationService.cancelNotifySchedule(
              link: anyNamed('link')))
          .called(1);
      verify(mockNotificationService.checkPreviousDayForNotify(
              schedule: anyNamed('schedule')))
          .called(1);
    });

    test('should trigger notification if schedule date is in the far future',
        () async {
      // Given
      final futureSchedule =
          tSchedule.copyWith(date: farFuture.toIso8601String());

      when(mockLocalSource.editSchedule(any)).thenAnswer((_) async => {});
      when(mockNotificationService.cancelNotifySchedule(link: anyNamed('link')))
          .thenAnswer((_) async => {});
      when(mockNotificationService.checkPreviousDayForNotify(
              schedule: anyNamed('schedule')))
          .thenAnswer((_) async => {});

      // When
      await repository.editSchedule(futureSchedule);

      // Then
      verify(mockLocalSource.editSchedule(any)).called(1);
      verify(mockNotificationService.cancelNotifySchedule(
              link: anyNamed('link')))
          .called(1);
      verify(mockNotificationService.checkPreviousDayForNotify(
              schedule: anyNamed('schedule')))
          .called(1);
    });
  });

  group('deleteSchedule', () {
    test('should delete schedule from local storage and cancel notification',
        () async {
      // Given
      when(mockLocalSource.deleteScheduleByLink(any))
          .thenAnswer((_) async => {});
      when(mockNotificationService.cancelNotifySchedule(link: anyNamed('link')))
          .thenAnswer((_) async => {});

      // When
      await repository.deleteSchedule(tUrl);

      // Then
      verify(mockLocalSource.deleteScheduleByLink(tUrl)).called(1);
      verify(mockNotificationService.cancelNotifySchedule(
              link: anyNamed('link')))
          .called(1);
    });
  });
}
