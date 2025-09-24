import 'dart:async';

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

    // TODO: Implement retry case for connection timeout(in remote source too)
    test(
        'should retry request when connection timeout occurs, then return Schedule successfully',
        () async {
      // Given
      when(mockRemoteSource.fetchScheduleFromServer(any))
          .thenThrow(TimeoutException('Connection timed out'))
          .thenAnswer((_) async => tScheduleModel);

      // When
      final result = await repository.analyzeLink(tUrl);

      // Then
      expect(result, tSchedule);
      verify(mockRemoteSource.fetchScheduleFromServer(tUrl)).called(2);
    });

    test('should throw Exception when remote source fails after retries',
        () async {
      // Given
      when(mockRemoteSource.fetchScheduleFromServer(any))
          .thenThrow(Exception("Server Error"));

      // When & Then
      expect(() => repository.analyzeLink(tUrl), throwsException);
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

  // Rewritten tests for BLoC implementation (Stream)
  group('getSchedules', () {
    test('should return a stream of schedule lists', () {
      // Given
      when(mockLocalSource.watchAllSchedules())
          .thenAnswer((_) => Stream.value([tScheduleModel]));

      // When
      final result = repository.getSchedules();

      // Then
      expect(result, emits([tSchedule]));
    });

    test(
        'should return updated list of schedules when dispose and refresh CalendarPage',
        () {
      // Given
      final updatedScheduleModel =
          tScheduleModel.copyWith(location: "Busan");
      final updatedSchedule = ScheduleMapper.toEntity(updatedScheduleModel);

      when(mockLocalSource.watchAllSchedules())
          .thenAnswer((_) => Stream.fromIterable([
                [tScheduleModel],
                [updatedScheduleModel]
              ]));

      // When
      final result = repository.getSchedules();

      // Then
      expect(
          result,
          emitsInOrder([
            [tSchedule],
            [updatedSchedule]
          ]));
    });
  });

  group('getSchedulesForMonth', () {
    final tDate = DateTime(2024, 6, 1);
    final tMap = {
      DateTime(2024, 6, 10): [tScheduleModel]
    };
    final tEntityMap = {
      DateTime(2024, 6, 10): [tSchedule]
    };

    test('should return a stream of schedule maps for the month', () {
      // Given
      when(mockLocalSource.watchSchedulesForMonth(tDate))
          .thenAnswer((_) => Stream.value(tMap));

      // When
      final result = repository.getSchedulesForMonth(tDate);

      // Then
      expect(result, emits(tEntityMap));
    });

    test(
        'should return updated map of schedules when dispose and refresh CalendarPage',
        () {
      // Given
      final updatedScheduleModel =
          tScheduleModel.copyWith(location: "Busan");
      final updatedMap = {
        DateTime(2024, 6, 10): [updatedScheduleModel]
      };
      final updatedEntityMap = {
        DateTime(2024, 6, 10): [ScheduleMapper.toEntity(updatedScheduleModel)]
      };

      when(mockLocalSource.watchSchedulesForMonth(tDate))
          .thenAnswer((_) => Stream.fromIterable([tMap, updatedMap]));

      // When
      final result = repository.getSchedulesForMonth(tDate);

      // Then
      expect(result, emitsInOrder([tEntityMap, updatedEntityMap]));
    });
  });

  group('editSchedule - Notification Behavior', () {
    test('should NOT trigger notification if schedule date is in the past',
        () async {
      // Given
      final pastSchedule = tSchedule.copyWith(date: yesterday);

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
          scheduleDate: anyNamed('scheduleDate'),
          payload: anyNamed('payload')));
    });

    test('should NOT trigger notification if schedule date is today', () async {
      // Given
      final todaySchedule = tSchedule.copyWith(date: today);

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
          scheduleDate: anyNamed('scheduleDate'),
          payload: anyNamed('payload')));
    });

    test('should trigger notification if schedule date is tomorrow', () async {
      // Given
      final tomorrowSchedule = tSchedule.copyWith(date: tomorrow);

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
      final futureSchedule = tSchedule.copyWith(date: farFuture);

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
