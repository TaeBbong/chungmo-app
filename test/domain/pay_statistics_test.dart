import 'package:chungmo/domain/entities/pay_statistics.dart';
import 'package:chungmo/domain/entities/relation.dart';
import 'package:chungmo/domain/entities/schedule.dart';
import 'package:flutter_test/flutter_test.dart';

Schedule buildSchedule({
  required String link,
  required int pay,
  int year = 2026,
  Relation relation = Relation.friend,
}) {
  return Schedule(
    link: link,
    thumbnail: '',
    groom: '철수',
    bride: '영희',
    date: DateTime(year, 10, 10),
    location: '서울',
    relation: relation,
    pay: pay,
  );
}

void main() {
  group('PayStatistics.fromSchedules', () {
    test('should aggregate totals per year and per relation', () {
      final stats = PayStatistics.fromSchedules([
        buildSchedule(link: 'a', pay: 100000, year: 2025),
        buildSchedule(link: 'b', pay: 50000, year: 2026),
        buildSchedule(
            link: 'c', pay: 200000, year: 2026, relation: Relation.family),
      ]);

      expect(stats.totalAmount, 350000);
      expect(stats.recordCount, 3);
      expect(stats.averageAmount, 116666);
      expect(stats.yearlyTotals, {2025: 100000, 2026: 250000});
      expect(stats.relationTotals,
          {Relation.friend: 150000, Relation.family: 200000});
    });

    test('should exclude unpaid records', () {
      final stats = PayStatistics.fromSchedules([
        buildSchedule(link: 'paid', pay: 100000),
        buildSchedule(link: 'unpaid', pay: 0),
      ]);

      expect(stats.recordCount, 1);
      expect(stats.totalAmount, 100000);
    });

    test('should stay empty and zero-safe without records', () {
      final stats = PayStatistics.fromSchedules(const []);

      expect(stats.isEmpty, isTrue);
      expect(stats.averageAmount, 0);
      expect(stats, PayStatistics.empty);
    });
  });
}
