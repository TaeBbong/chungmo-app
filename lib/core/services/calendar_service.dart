import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/schedule.dart';

/// Hands a saved [Schedule] off to the platform's default calendar app.
///
/// This is the OS-level "insert event" handoff (ACTION_INSERT on Android,
/// EKEventEditViewController on iOS): the user confirms inside their own
/// calendar app, so no calendar permission or event bookkeeping is needed.
/// The trade-off is that the copy is one-way — editing or deleting the
/// schedule in chungmo does not touch the exported event.
abstract class CalendarService {
  Future<bool> addToCalendar(Schedule schedule);
}

@LazySingleton(as: CalendarService)
class CalendarServiceImpl implements CalendarService {
  /// A Korean wedding, including the meal, blocks out about two hours.
  static const Duration eventDuration = Duration(hours: 2);

  @override
  Future<bool> addToCalendar(Schedule schedule) {
    return Add2Calendar.addEvent2Cal(buildEvent(schedule));
  }

  /// Maps a schedule onto the event handed to the OS. Static so the mapping
  /// stays unit-testable without going through the platform channel.
  static Event buildEvent(Schedule schedule) {
    return Event(
      title: '${schedule.groom} ♥ ${schedule.bride} 결혼식',
      location: schedule.location,
      startDate: schedule.date,
      endDate: schedule.date.add(eventDuration),
      description: _isHttpLink(schedule.link) ? '청첩장: ${schedule.link}' : null,
    );
  }

  /// True for real invitation URLs, false for the synthetic keys
  /// (image://, text://, manual://) that would be noise in a calendar note.
  static bool _isHttpLink(String link) {
    final Uri? uri = Uri.tryParse(link);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }
}
