/// Tests for the schedule database and the stream every screen reads from.
///
/// These run against a real SQLite file through `sqflite_common_ffi`, not a
/// mock: the things worth testing here — that a migration adds a column
/// without losing rows, that a NULL column reads back as the model default —
/// are properties of the database, and a mock would assert nothing about them.
library;

import 'dart:io';

import 'package:chungmo/data/models/schedule/schedule_model.dart';
import 'package:chungmo/data/sources/local/schedule_local_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

ScheduleModel _model(String link, {String groom = '김민준'}) => ScheduleModel(
      link: link,
      thumbnail: 'https://example.test/thumb.png',
      groom: groom,
      bride: '이서연',
      date: '2026-10-17T13:30:00.000+09:00',
      location: '라온컨벤션 3층 그랜드홀',
      venue: '라온컨벤션',
    );

/// Counts how often the table is actually read, which is the claim the
/// seeding makes: later subscribers are served from the cached list.
class _CountingSource extends ScheduleLocalSourceImpl {
  int reads = 0;

  @override
  Future<List<ScheduleModel>> getAllSchedulesOnce() {
    reads++;
    return super.getAllSchedulesOnce();
  }
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;
  late ScheduleLocalSourceImpl source;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('chungmo_db_test');
    ScheduleLocalSourceImpl.databasePathOverride = '${tempDir.path}/test.db';
    source = ScheduleLocalSourceImpl();
  });

  tearDown(() async {
    source.dispose();  // idempotent: a test may have disposed already
    ScheduleLocalSourceImpl.databasePathOverride = null;
    await tempDir.delete(recursive: true);
  });

  group('lifecycle', () {
    test('an emit that lands after dispose is dropped, not thrown', () async {
      // dispose closes the controller. A read started before it finishes
      // afterwards, and adding to a closed controller throws into the zone;
      // awaiting the emit directly makes that deterministic.
      await source.saveSchedule(_model('https://invite.test/a'));
      source.dispose();

      await expectLater(source.emitAllSchedules(), completes);
    });
  });

  group('CRUD', () {
    test('saves and reads a schedule back by link', () async {
      await source.saveSchedule(_model('https://invite.test/a'));

      final read = await source.getScheduleByLink('https://invite.test/a');
      expect(read?.groom, '김민준');
      expect(read?.venue, '라온컨벤션');
    });

    test('returns null for a link that was never saved', () async {
      expect(await source.getScheduleByLink('https://invite.test/missing'),
          isNull);
    });

    test('an edit replaces the row rather than adding one', () async {
      await source.saveSchedule(_model('https://invite.test/a'));
      await source
          .editSchedule(_model('https://invite.test/a', groom: '박도윤'));

      final all = await source.getAllSchedulesOnce();
      expect(all, hasLength(1));
      expect(all.single.groom, '박도윤');
    });

    test('deletes by link', () async {
      await source.saveSchedule(_model('https://invite.test/a'));
      await source.saveSchedule(_model('https://invite.test/b'));

      await source.deleteScheduleByLink('https://invite.test/a');

      expect((await source.getAllSchedulesOnce()).single.link,
          'https://invite.test/b');
    });
  });

  group('watchAllSchedules', () {
    test('emits the current contents to a first subscriber', () async {
      await source.saveSchedule(_model('https://invite.test/a'));

      final first = await source.watchAllSchedules().first;

      expect(first.single.link, 'https://invite.test/a');
    });

    test('emits again on save, edit and delete', () async {
      final emissions = <List<ScheduleModel>>[];
      final sub = source.watchAllSchedules().listen(emissions.add);
      await pumpEventQueue();

      await source.saveSchedule(_model('https://invite.test/a'));
      await source.editSchedule(_model('https://invite.test/a', groom: '박도윤'));
      await source.deleteScheduleByLink('https://invite.test/a');
      await pumpEventQueue();

      expect(emissions.map((e) => e.length), containsAllInOrder([0, 1, 1, 0]));
      expect(emissions.last, isEmpty);
      await sub.cancel();
    });

    test('a subscriber that attaches late still receives the current list',
        () async {
      await source.saveSchedule(_model('https://invite.test/a'));
      // Drain the first read so _latest is populated and the broadcast
      // event for it is long gone.
      await source.watchAllSchedules().first;
      await pumpEventQueue();

      // The failure this guards against: an `await` between asking for the
      // stream and listening to it. On a bare broadcast stream the new
      // subscriber would sit empty until the next write — the v1.0.2 bug.
      final stream = source.watchAllSchedules();
      await pumpEventQueue();
      final received = await stream.first.timeout(const Duration(seconds: 2));

      expect(received.single.link, 'https://invite.test/a');
    });

    test('every subscriber sees a later write', () async {
      final a = <List<ScheduleModel>>[];
      final b = <List<ScheduleModel>>[];
      final subA = source.watchAllSchedules().listen(a.add);
      final subB = source.watchAllSchedules().listen(b.add);
      await pumpEventQueue();

      await source.saveSchedule(_model('https://invite.test/a'));
      await pumpEventQueue();

      expect(a.last.single.link, 'https://invite.test/a');
      expect(b.last.single.link, 'https://invite.test/a');
      await subA.cancel();
      await subB.cancel();
    });

    test('reads the table once however many subscribers attach', () async {
      // Every subscriber used to trigger its own refresh, so the four
      // screens that watch this stream meant four full table reads at
      // startup, each broadcast to all four.
      final counting = _CountingSource();
      final subs = [
        for (var i = 0; i < 4; i++) counting.watchAllSchedules().listen(null)
      ];
      await pumpEventQueue();

      expect(counting.reads, 1);
      for (final s in subs) {
        await s.cancel();
      }
      counting.dispose();
    });
  });

  group('migration', () {
    /// The schema as of v3: accounts and attendance exist, but `relation`
    /// and `relation_note` (v4) and `venue` (v5) do not.
    Future<void> createV3Database(String path) async {
      final db = await databaseFactory.openDatabase(path,
          options: OpenDatabaseOptions(
            version: 3,
            onCreate: (db, version) async {
              await db.execute('''
                CREATE TABLE schedules (
                  link TEXT PRIMARY KEY,
                  thumbnail TEXT,
                  groom TEXT,
                  bride TEXT,
                  datetime TEXT,
                  location TEXT,
                  groom_accounts TEXT,
                  bride_accounts TEXT,
                  attendance TEXT,
                  pay INTEGER
                )
              ''');
            },
          ));
      await db.insert('schedules', {
        'link': 'https://invite.test/old',
        'thumbnail': 'https://example.test/thumb.png',
        'groom': '김민준',
        'bride': '이서연',
        'datetime': '2026-10-17T13:30:00.000+09:00',
        'location': '라온컨벤션 3층 그랜드홀',
        'groom_accounts': '[]',
        'bride_accounts': '[]',
        'attendance': 'undecided',
        'pay': 0,
      });
      await db.close();
    }

    test('upgrading from v3 keeps existing rows and adds the new columns',
        () async {
      final path = '${tempDir.path}/upgrade.db';
      await createV3Database(path);
      ScheduleLocalSourceImpl.databasePathOverride = path;
      final upgraded = ScheduleLocalSourceImpl();

      final rows = await upgraded.getAllSchedulesOnce();

      expect(rows, hasLength(1));
      expect(rows.single.link, 'https://invite.test/old');
      expect(rows.single.location, '라온컨벤션 3층 그랜드홀');
      // The columns added by the upgrade are NULL for an existing row and
      // have to read back as the model's defaults, not as an error.
      expect(rows.single.venue, '');
      expect(rows.single.relationNote, '');
      expect(rows.single.relation, 'unset');
      upgraded.dispose();
    });

    test('an upgraded database accepts a venue on the next write', () async {
      final path = '${tempDir.path}/upgrade_write.db';
      await createV3Database(path);
      ScheduleLocalSourceImpl.databasePathOverride = path;
      final upgraded = ScheduleLocalSourceImpl();

      final existing =
          (await upgraded.getScheduleByLink('https://invite.test/old'))!;
      await upgraded.editSchedule(existing.copyWith(venue: '라온컨벤션'));

      expect(
          (await upgraded.getScheduleByLink('https://invite.test/old'))?.venue,
          '라온컨벤션');
      upgraded.dispose();
    });
  });
}
