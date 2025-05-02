import 'constants.dart';

extension DateExtension on DateTime {
  String get krDate {
    String formatDate =
        '$month월 $day일(${Constants.weekdays[weekday - 1]}) $hour시';
    if (minute != 0) formatDate += '$minute분';
    return formatDate;
  }
}
