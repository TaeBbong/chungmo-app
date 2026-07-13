import 'package:chungmo/data/mapper/schedule_mapper.dart';
import 'package:chungmo/data/models/schedule/schedule_model.dart';
import 'package:chungmo/domain/entities/account.dart';
import 'package:chungmo/domain/entities/attendance.dart';
import 'package:chungmo/domain/entities/schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tSchedule = Schedule(
    link: 'https://test.com',
    thumbnail: 'https://test.com/thumbnail.jpg',
    groom: 'John',
    bride: 'Jane',
    date: DateTime(2024, 6, 10),
    location: 'Seoul',
    groomAccounts: const [
      Account(bank: '국민', number: '123-45-6789', holder: '김철수', relation: '신랑'),
      Account(bank: '농협', number: '302-1111', holder: '김아버지', relation: '아버지'),
    ],
    brideAccounts: const [
      Account(bank: '신한', number: '110-222-333', holder: '이영희', relation: '신부'),
    ],
    attendance: Attendance.attending,
    pay: 100000,
  );

  group('accounts serialization', () {
    test('should preserve accounts across toModel -> toEntity round trip', () {
      final result = ScheduleMapper.toEntity(ScheduleMapper.toModel(tSchedule));

      expect(result, tSchedule);
    });

    test('should encode accounts as a JSON array in a single text field', () {
      final model = ScheduleMapper.toModel(tSchedule);

      expect(model.groomAccounts, contains('"number":"123-45-6789"'));
      expect(model.brideAccounts, contains('"holder":"이영희"'));
    });

    test('should decode null columns (pre-migration rows) into defaults', () {
      // sqflite returns the added columns as null for rows written before the
      // migration that added them.
      final model = ScheduleModel.fromJson({
        'link': 'https://test.com',
        'thumbnail': 'https://test.com/thumbnail.jpg',
        'groom': 'John',
        'bride': 'Jane',
        'datetime': DateTime(2024, 6, 10).toIso8601String(),
        'location': 'Seoul',
        'groom_accounts': null,
        'bride_accounts': null,
        'attendance': null,
        'pay': null,
      });

      final result = ScheduleMapper.toEntity(model);

      expect(result.groomAccounts, isEmpty);
      expect(result.brideAccounts, isEmpty);
      expect(result.attendance, Attendance.undecided);
      expect(result.pay, 0);
    });

    test('should decode malformed payload into empty list', () {
      expect(ScheduleMapper.decodeAccounts('not json'), isEmpty);
      expect(ScheduleMapper.decodeAccounts('{"bank":"국민"}'), isEmpty);
    });

    test('should decode partial account object with empty defaults', () {
      final result = ScheduleMapper.decodeAccounts('[{"number":"123-456"}]');

      expect(result, const [Account(number: '123-456')]);
    });
  });
}
