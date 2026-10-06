/// Tests for the day-before reminder rule.
///
/// `addNotifySchedule` is the boundary: everything above it is the decision
/// of whether and when to remind, everything below it is the plugin. A
/// subclass records what the decision asked for, so no platform channel is
/// involved.
library;

import 'package:chungmo/core/services/notification_service.dart';
import 'package:chungmo/domain/entities/schedule.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class _Scheduled {
  final String title;
  final tz.TZDateTime at;
  final String payload;

  const _Scheduled(this.title, this.at, this.payload);
}

class _RecordingService extends NotificationServiceImpl {
  final List<_Scheduled> scheduled = [];

  _RecordingService(tz.TZDateTime now) : super.withClock(((_) => now));

  @override
  Future<void> addNotifySchedule({
    required int id,
    required String appName,
    required String title,
    required tz.TZDateTime scheduleDate,
    required String payload,
  }) async {
    scheduled.add(_Scheduled(title, scheduleDate, payload));
  }
}

Schedule _wedding(DateTime date) => Schedule(
      link: 'https://invite.test/a',
      thumbnail: '',
      groom: '김민준',
      bride: '이서연',
      date: date,
      location: '라온컨벤션 3층 그랜드홀',
      venue: '라온컨벤션',
      groomAccounts: const [],
      brideAccounts: const [],
    );

void main() {
  late tz.Location seoul;

  setUpAll(() {
    tzdata.initializeTimeZones();
    seoul = tz.getLocation('Asia/Seoul');
  });

  /// A clock stopped at the given Seoul wall time.
  tz.TZDateTime at(int day, int hour, [int minute = 0]) =>
      tz.TZDateTime(seoul, 2026, 11, day, hour, minute);

  /// A wedding on 2026-11-[day] at noon Seoul time.
  ///
  /// A Seoul instant rather than a local `DateTime`: the rule converts what
  /// it is given, so stating a wall-clock time here would mean a different
  /// moment on a machine outside Korea and these cases would turn on where
  /// the suite runs.
  Schedule wedding(int day) => _wedding(at(day, 12));

  group('the morning before', () {
    test('reminds at 09:00 the day before', () async {
      final service = _RecordingService(at(10, 15));

      await service.checkPreviousDayForNotify(schedule: wedding(15));

      final reminder = service.scheduled.single;
      expect(reminder.at, at(14, 9));
      expect(reminder.title, startsWith('내일'));
      expect(reminder.at.location.name, 'Asia/Seoul');
    });

    test('names the couple and carries the link to the detail page', () async {
      final service = _RecordingService(at(10, 15));

      await service.checkPreviousDayForNotify(schedule: wedding(15));

      final reminder = service.scheduled.single;
      expect(reminder.title, contains('김민준'));
      expect(reminder.title, contains('이서연'));
      expect(reminder.payload, 'https://invite.test/a');
    });

    test('takes the slot with an hour to spare', () async {
      // The old guard compared against a fixed 11:00, so it threw this away
      // even though the reminder was still an hour off (#67).
      final service = _RecordingService(at(14, 8));

      await service.checkPreviousDayForNotify(schedule: wedding(15));

      expect(service.scheduled.single.at, at(14, 9));
      expect(service.scheduled.single.title, startsWith('내일'));
    });
  });

  group('the morning of', () {
    test('reminds on the day when the invitation arrives the night before',
        () async {
      // Saved at 22:00 for tomorrow: the day-before slot has gone, the
      // wedding has not. This wording had never been sent (#67).
      final service = _RecordingService(at(14, 22));

      await service.checkPreviousDayForNotify(schedule: wedding(15));

      final reminder = service.scheduled.single;
      expect(reminder.at, at(15, 9));
      expect(reminder.title, startsWith('오늘'));
      expect(reminder.title, contains('김민준'));
      expect(reminder.title, contains('이서연'));
      expect(reminder.payload, 'https://invite.test/a');
    });

    test('standing exactly on the day-before slot moves to the day itself',
        () async {
      // A notification scheduled for the current instant would fire at
      // once, which is not a reminder — so the slot counts as gone.
      final service = _RecordingService(at(14, 9));

      await service.checkPreviousDayForNotify(schedule: wedding(15));

      expect(service.scheduled.single.at, at(15, 9));
      expect(service.scheduled.single.title, startsWith('오늘'));
    });

    test('reminds for a wedding later today', () async {
      final service = _RecordingService(at(15, 8));

      await service.checkPreviousDayForNotify(schedule: wedding(15));

      expect(service.scheduled.single.at, at(15, 9));
      expect(service.scheduled.single.title, startsWith('오늘'));
    });
  });

  group('nothing left to remind about', () {
    test('a wedding that starts before the reminder hour', () async {
      // The slot is 09:00; a ceremony at 08:00 would be reminded about an
      // hour after it began, which is worse than silence.
      final service = _RecordingService(at(15, 7));

      await service.checkPreviousDayForNotify(schedule: _wedding(at(15, 8)));

      expect(service.scheduled, isEmpty);
    });

    test('both slots gone on the wedding day', () async {
      final service = _RecordingService(at(15, 10));

      await service.checkPreviousDayForNotify(schedule: wedding(15));

      expect(service.scheduled, isEmpty);
    });

    test('the wedding has already happened', () async {
      final service = _RecordingService(at(20, 9));

      await service.checkPreviousDayForNotify(schedule: wedding(15));

      expect(service.scheduled, isEmpty);
    });
  });

  test('reads the wedding as an instant, not as Seoul wall-clock fields',
      () async {
    // `ScheduleMapper.toEntity` returns the right instant in the device's
    // own zone, so on a phone outside Korea a 12:00 Seoul ceremony arrives
    // with 03:00 in its fields. Reading those as Seoul moved the wedding
    // nine hours and silently dropped the same-day reminder.
    final asUtc = _wedding(DateTime.utc(2026, 11, 15, 3));
    final service = _RecordingService(at(14, 22));

    await service.checkPreviousDayForNotify(schedule: asUtc);

    expect(service.scheduled.single.at, at(15, 9));
    expect(service.scheduled.single.title, startsWith('오늘'));
  });

  test('two weddings get two reminders, keyed apart by link', () async {
    final service = _RecordingService(at(10, 15));

    await service.checkPreviousDayForNotify(schedule: wedding(15));
    await service.checkPreviousDayForNotify(
        schedule: wedding(20).copyWith(
            link: 'https://invite.test/b', groom: '박도윤', bride: '최서윤'));

    expect(service.scheduled, hasLength(2));
    expect(service.scheduled.last.at, at(19, 9));
    expect(service.scheduled.last.payload, 'https://invite.test/b');
    expect(service.scheduled.last.title, contains('박도윤'));
  });
}
