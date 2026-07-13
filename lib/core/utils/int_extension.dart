extension IntExtension on int {
  /// `150000` -> `150,000원`
  String get krCurrency {
    final String digits = toString();
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    buffer.write('원');

    return buffer.toString();
  }
}
