import 'constants.dart';

extension DateExtension on DateTime {
  /// e.g. `2025년 10월 26일(일) 14시`.
  ///
  /// The year is spelled out: past schedules pile up across years, and without
  /// it a list of them reads as if the dates were shuffled.
  String get krDate {
    String formatDate =
        '$year년 $month월 $day일(${Constants.weekdays[weekday - 1]}) $hour시';
    if (minute != 0) formatDate += '$minute분';
    return formatDate;
  }

  /// Days left until this date, counted by calendar day rather than by
  /// elapsed hours, so an event later today is 0 and tomorrow is always 1.
  int get daysLeft {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    return DateTime(year, month, day).difference(today).inDays;
  }

  /// Whether the wedding day itself has passed.
  ///
  /// Counted by calendar day, like [daysLeft]: a wedding held earlier today is
  /// still 'today', not past. Splitting a list by `isBefore(DateTime.now())`
  /// instead would file it under 'past' while its badge still reads `D-DAY`.
  bool get isPastDay => daysLeft < 0;

  /// `D-23`, `D-DAY`, `D+3`
  String get ddayLabel {
    final int days = daysLeft;
    if (days == 0) return 'D-DAY';
    return days > 0 ? 'D-$days' : 'D+${-days}';
  }

  /// Human phrasing shown next to the badge, e.g. `내일이에요`.
  String get ddayDescription {
    final int days = daysLeft;
    if (days == 0) return '오늘이에요 🎉';
    if (days == 1) return '내일이에요';
    if (days > 1) return '$days일 남았어요';
    return '지난 일정이에요';
  }
}
