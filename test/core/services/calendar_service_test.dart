import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:chungmo/core/services/calendar_service.dart';
import 'package:chungmo/domain/entities/schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarServiceImpl.buildEvent', () {
    final Schedule schedule = Schedule(
      link: 'https://invitation.example.com/card',
      thumbnail: 'thumb',
      groom: '김철수',
      bride: '이영희',
      date: DateTime(2026, 10, 24, 13, 0),
      location: '그랜드홀 3층',
    );

    test('maps names, location and the two-hour ceremony block', () {
      final Event event = CalendarServiceImpl.buildEvent(schedule);

      expect(event.title, '김철수 ♥ 이영희 결혼식');
      expect(event.location, '그랜드홀 3층');
      expect(event.startDate, DateTime(2026, 10, 24, 13, 0));
      expect(event.endDate,
          DateTime(2026, 10, 24, 13, 0).add(CalendarServiceImpl.eventDuration));
    });

    test('keeps the invitation URL in the description', () {
      final Event event = CalendarServiceImpl.buildEvent(schedule);

      expect(event.description, contains('https://invitation.example.com/card'));
    });

    test('drops synthetic keys (image://, text://, manual://) from the note',
        () {
      for (final String link in [
        'image://12345',
        'text://67890',
        'manual://1700000000000',
      ]) {
        final Event event = CalendarServiceImpl.buildEvent(
          schedule.copyWith(link: link),
        );

        expect(event.description, isNull, reason: link);
      }
    });
  });
}
