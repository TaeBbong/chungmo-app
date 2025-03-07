import 'constants.dart';

class DateConverter {
  static String generateKrDate(String date) {
    final DateTime dateTime = DateTime.parse(date);
    String formatDate =
        '${dateTime.month}월 ${dateTime.day}일(${Constants.weekdays[dateTime.weekday - 1]}) ${dateTime.hour}시';
    if (dateTime.minute != 0) formatDate += '${dateTime.minute}분';
    return formatDate;
  }
}
