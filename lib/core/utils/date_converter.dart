import 'constants.dart';

class DateConverter {
  /// Convert formatted string `date`(2020-11-27:11:00:00) into K-style string `formatDate`(11월 27일 11시 30분)
  ///
  /// Doesn't add `분` if minute == 0
  static String generateKrDate(DateTime date) {
    String formatDate =
        '${date.month}월 ${date.day}일(${Constants.weekdays[date.weekday - 1]}) ${date.hour}시';
    if (date.minute != 0) formatDate += '${date.minute}분';
    return formatDate;
  }
}
