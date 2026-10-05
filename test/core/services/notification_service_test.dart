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
  late _RecordingService service;
  late tz.Location seoul;

  setUpAll(() {
    tzdata.initializeTimeZones();
    seoul = tz.getLocation('Asia/Seoul');
  });

  setUp(() => service = _RecordingService());

  /// A wedding [days] from now, at noon Seoul time.
  DateTime weddingIn(int days) {
    final now = tz.TZDateTime.now(seoul);
    final day = now.add(Duration(days: days));
    return DateTime(day.year, day.month, day.day, 12, 0);
  }

  test('reminds the morning before the wedding', () async {
    await service.checkPreviousDayForNotify(schedule: _wedding(weddingIn(5)));

    expect(service.scheduled, hasLength(1));
    final reminder = service.scheduled.single;
    expect(reminder.at.hour, 9);
    expect(reminder.at.minute, 0);
    expect(reminder.at.location.name, 'Asia/Seoul');
    // The day before the wedding, whatever the wedding's own time.
    final wedding = weddingIn(5);
    expect(
        reminder.at.day,
        DateTime(wedding.year, wedding.month, wedding.day)
            .subtract(const Duration(days: 1))
            .day);
  });

  test('names the couple and carries the link back to the detail page',
      () async {
    await service.checkPreviousDayForNotify(schedule: _wedding(weddingIn(5)));

    final reminder = service.scheduled.single;
    expect(reminder.title, contains('김민준'));
    expect(reminder.title, contains('이서연'));
    expect(reminder.title, startsWith('내일'));
    // The payload is what the tap handler looks the schedule up by.
    expect(reminder.payload, 'https://invite.test/a');
  });

  test('schedules nothing for a wedding that has already happened', () async {
    await service.checkPreviousDayForNotify(schedule: _wedding(weddingIn(-3)));

    expect(service.scheduled, isEmpty);
  });

  test('schedules nothing for a wedding held today', () async {
    // The reminder slot was yesterday morning; there is nothing left to
    // schedule for it.
    await service.checkPreviousDayForNotify(schedule: _wedding(weddingIn(0)));

    expect(service.scheduled, isEmpty);
  });

  test('schedules nothing for a wedding tomorrow — a known defect', () async {
    // Recorded, not endorsed. The reminder slot for a wedding tomorrow is
    // today at 09:00, and the guard drops it by comparing against a fixed
    // 11:00 rather than against now — so the slot is discarded even at
    // 08:00, when it is still an hour away. See issue #67.
    await service.checkPreviousDayForNotify(schedule: _wedding(weddingIn(1)));

    expect(service.scheduled, isEmpty);
  });

  test('never produces the same-day wording — a known defect', () async {
    // The branch that would say '오늘 ... 결혼식이 있습니다' asks whether the
    // 09:00 slot is the same instant as 11:00 today, which it cannot be.
    // Nothing the caller passes can reach it. See issue #67.
    for (final days in [0, 1, 2, 5, 30]) {
      await service.checkPreviousDayForNotify(
          schedule: _wedding(weddingIn(days)));
    }

    expect(
        service.scheduled.map((s) => s.title), everyElement(startsWith('내일')));
  });

  test('two weddings get two reminders, keyed apart by link', () async {
    await service.checkPreviousDayForNotify(schedule: _wedding(weddingIn(5)));
    await service.checkPreviousDayForNotify(
        schedule: _wedding(weddingIn(9)).copyWith(
            link: 'https://invite.test/b', groom: '박도윤', bride: '최서윤'));

    expect(service.scheduled, hasLength(2));
    expect(service.scheduled.last.payload, 'https://invite.test/b');
    expect(service.scheduled.last.title, contains('박도윤'));
  });
}
