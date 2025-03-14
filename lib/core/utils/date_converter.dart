import 'constants.dart';

class DateConverter {
  /// Convert formatted string `date`(2020-11-27:11:00:00) into K-style string `formatDate`(11월 27일 11시 30분)
  ///
  /// Doesn't add `분` if minute == 0
  static String generateKrDate(String date) {
    final DateTime dateTime = DateTime.parse(date);
    String formatDate =
        '${dateTime.month}월 ${dateTime.day}일(${Constants.weekdays[dateTime.weekday - 1]}) ${dateTime.hour}시';
    if (dateTime.minute != 0) formatDate += '${dateTime.minute}분';
    return formatDate;
  }
}
