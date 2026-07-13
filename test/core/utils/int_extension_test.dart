import 'package:chungmo/core/utils/int_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('krCurrency', () {
    test('should group digits by thousands', () {
      expect(100000.krCurrency, '100,000원');
      expect(50000.krCurrency, '50,000원');
      expect(1234567.krCurrency, '1,234,567원');
    });

    test('should not add a separator below a thousand', () {
      expect(0.krCurrency, '0원');
      expect(999.krCurrency, '999원');
    });
  });
}
