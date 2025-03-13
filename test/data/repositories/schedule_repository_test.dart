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
      when(mockNotificationService.notifyScheduleAtPreviousDay(
              schedule: anyNamed('schedule')))
          .thenAnswer((_) async => {});

      // When
      await repository.saveSchedule(tSchedule);

      // Then
      verify(mockLocalSource.saveSchedule(any)).called(1);
      verify(mockNotificationService.notifyScheduleAtPreviousDay(
              schedule: anyNamed('schedule')))
          .called(1);
    });
  });

  group('getSchedules', () {
    test('should return list of schedules when local source is successful',
        () async {
      // Given
      when(mockLocalSource.getSchedules())
          .thenAnswer((_) async => [tScheduleModel]);

      // When
      final result = await repository.getSchedules();

      // Then
      expect(result, [tSchedule]);
      verify(mockLocalSource.getSchedules()).called(1);
    });
  });

  group('getSchedulesByDate', () {
    final tDate = DateTime(2024, 6, 10);

    test('should return list of schedules for a specific date', () async {
      // Given
      when(mockLocalSource.getSchedulesByDate(tDate))
          .thenAnswer((_) async => [tScheduleModel]);

      // When
      final result = await repository.getSchedulesByDate(tDate);

      // Then
      expect(result, [tSchedule]);
      verify(mockLocalSource.getSchedulesByDate(tDate)).called(1);
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

  group('editSchedule', () {
    test('should update schedule in local storage and re-trigger notification',
        () async {
      // Given
      when(mockLocalSource.editSchedule(any)).thenAnswer((_) async => {});
      when(mockNotificationService.cancelNotifySchedule(link: anyNamed('link')))
          .thenAnswer((_) async => {});
      when(mockNotificationService.notifyScheduleAtPreviousDay(
              schedule: anyNamed('schedule')))
          .thenAnswer((_) async => {});

      // When
      await repository.editSchedule(tSchedule);

      // Then
      verify(mockLocalSource.editSchedule(any)).called(1);
      verify(mockNotificationService.cancelNotifySchedule(
              link: anyNamed('link')))
          .called(1);
      verify(mockNotificationService.notifyScheduleAtPreviousDay(
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
