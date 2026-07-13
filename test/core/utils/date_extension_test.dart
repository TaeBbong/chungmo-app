import 'package:chungmo/core/utils/date_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);

  group('D-day', () {
    test('should count by calendar day, not elapsed hours', () {
      expect(today.add(const Duration(hours: 1)).daysLeft, 0);
      expect(today.add(const Duration(days: 1, hours: 1)).daysLeft, 1);
      expect(today.subtract(const Duration(hours: 1)).daysLeft, -1);
    });

    test('should label the wedding day as D-DAY', () {
      expect(today.add(const Duration(hours: 9)).ddayLabel, 'D-DAY');
      expect(today.add(const Duration(days: 23)).ddayLabel, 'D-23');
      expect(today.subtract(const Duration(days: 3)).ddayLabel, 'D+3');
    });
  });

  group('isPastDay', () {
    test('should not treat a wedding held earlier today as past', () {
      // Otherwise the list files it under '지난 일정' while its badge reads D-DAY.
      expect(today.isPastDay, isFalse);
      expect(today.add(const Duration(hours: 1)).isPastDay, isFalse);
    });

    test('should treat yesterday as past', () {
      expect(today.subtract(const Duration(minutes: 1)).isPastDay, isTrue);
    });
  });
}
