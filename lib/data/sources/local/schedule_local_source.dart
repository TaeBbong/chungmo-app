/// Step 5:
/// Data source
///
/// CRUD based data source implement with remote/local source

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/schedule/schedule_model.dart';

abstract class ScheduleLocalSource {
  Stream<List<ScheduleModel>> watchAllSchedules();

  Future<void> emitAllSchedules();

  /// Create `schedule` data row from model `ScheduleModel`.
  Future<void> saveSchedule(ScheduleModel schedule);

  /// Update `schedule` data row from updated instance type `ScheduleModel`.
  Future<void> editSchedule(ScheduleModel schedule);

  /// Deletes `schedule` from db by key `link`.
  Future<void> deleteScheduleByLink(String link);

  Future<ScheduleModel?> getScheduleByLink(String link);

  /// One-shot read of every schedule, for aggregations that don't need
  /// the reactive stream (e.g. gift-amount statistics).
  Future<List<ScheduleModel>> getAllSchedulesOnce();

  Future<void> refresh();
}

@LazySingleton(as: ScheduleLocalSource)
class ScheduleLocalSourceImpl implements ScheduleLocalSource {
  /// Overrides where the database file lives. Tests point it at a temporary
  /// directory; production leaves it null and uses the platform default.
  /// Kept off the constructor so the injectable registration stays a plain
  /// zero-argument one.
  @visibleForTesting
  static String? databasePathOverride;

  Database? _database;

  final _controller = StreamController<List<ScheduleModel>>.broadcast();

  /// The last list handed out, replayed to every new subscriber.
  ///
  /// A broadcast controller does not replay, so without this a subscriber
  /// that attaches after the first read — anything with an `await` before
  /// its `listen` — would see nothing until the next write. Every write
  /// goes through this class, so the cached list cannot go stale.
  List<ScheduleModel>? _latest;

  /// The first read, while it is still in flight. Screens are built together,
  /// so all four subscribers ask before any of them has an answer; without
  /// this they would each start their own read of the same table.
  Future<void>? _firstRead;

  /// Getter for internal `_database`.
  ///
  /// If not initialized, initDB then returns `_database`.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  /// Initialize DB with `CREATE TABLE schedules`.
  Future<Database> _initDB() async {
    final path = databasePathOverride ??
        join(await getDatabasesPath(), 'schedule_database.db');
    return await openDatabase(
      path,
      version: 5,
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
            pay INTEGER,
            relation TEXT,
            relation_note TEXT,
            venue TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // UPDATE: 축의금 accounts ('groom_accounts', 'bride_accounts').
          // Existing rows keep NULL, which ScheduleMapper reads as an empty list.
          await db
              .execute('ALTER TABLE schedules ADD COLUMN groom_accounts TEXT;');
          await db
              .execute('ALTER TABLE schedules ADD COLUMN bride_accounts TEXT;');
        }
        if (oldVersion < 3) {
          // UPDATE: attendance & 축의금 the user gave ('attendance', 'pay').
          // Existing rows keep NULL, read back as `undecided` / 0.
          await db.execute('ALTER TABLE schedules ADD COLUMN attendance TEXT;');
          await db.execute('ALTER TABLE schedules ADD COLUMN pay INTEGER;');
        }
        if (oldVersion < 4) {
          // UPDATE: relationship to the couple ('relation', 'relation_note').
          // Existing rows keep NULL, read back as `unset` / ''.
          await db.execute('ALTER TABLE schedules ADD COLUMN relation TEXT;');
          await db
              .execute('ALTER TABLE schedules ADD COLUMN relation_note TEXT;');
        }
        if (oldVersion < 5) {
          // UPDATE: searchable place name for map hand-offs ('venue').
          // Existing rows keep NULL, read back as '' and the map search
          // falls back to the full location string.
          await db.execute('ALTER TABLE schedules ADD COLUMN venue TEXT;');
        }
      },
    );
  }

  @override
  Future<void> emitAllSchedules() async {
    final schedules = await getAllSchedulesOnce();
    _latest = schedules;
    // A read started before dispose can land after it; there is nobody left
    // to tell, and adding to a closed controller throws.
    if (_controller.isClosed) return;
    _controller.add(schedules);
  }

  @override
  Stream<List<ScheduleModel>> watchAllSchedules() {
    // Only the first subscriber pays for a read. Later ones are seeded with
    // what that read produced, which is current because every write emits.
    if (_latest == null) {
      // The interface is synchronous, so this read cannot be awaited and its
      // failure has nowhere to go but the stream subscribers already listen
      // to. Left unhandled it reaches the zone handler, which reports a
      // still-running app as a fatal crash. `_latest` stays null either way,
      // so the next subscriber retries the read.
      _firstRead ??= refresh().catchError((Object error, StackTrace stack) {
        if (!_controller.isClosed) _controller.addError(error, stack);
      }).whenComplete(() => _firstRead = null);
    }
    return _seeded();
  }

  /// The broadcast stream with the last known list prepended, per subscriber.
  ///
  /// The listener is attached before the seed is added so no event can slip
  /// through the gap, and broadcast events are delivered asynchronously, so
  /// the synchronous seed is always the first thing a subscriber sees.
  Stream<List<ScheduleModel>> _seeded() =>
      Stream<List<ScheduleModel>>.multi((controller) {
        final subscription = _controller.stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
        controller.onCancel = subscription.cancel;
        final seed = _latest;
        if (seed != null) controller.add(seed);
      });

  /// Create `schedule` data row from model `ScheduleModel`.
  @override
  Future<void> saveSchedule(ScheduleModel schedule) async {
    final db = await database;
    await db.insert(
      'schedules',
      schedule.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await emitAllSchedules();
  }

  /// Update `schedule` data row from updated instance type `ScheduleModel`.
  @override
  Future<void> editSchedule(ScheduleModel schedule) async {
    final db = await database;
    await db.update(
      'schedules',
      schedule.toJson(),
      where: 'link = ?',
      whereArgs: [schedule.link],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await emitAllSchedules();
  }

  /// Deletes `schedule` from db by key `link`.
  @override
  Future<void> deleteScheduleByLink(String link) async {
    final db = await database;
    await db.delete(
      'schedules',
      where: "link = ?",
      whereArgs: [link],
    );
    await emitAllSchedules();
    return;
  }

  /// Retrieve a `schedule` in type `ScheduleModel` by key `link`.
  ///
  /// If no matching results, returns `null`.
  @override
  Future<ScheduleModel?> getScheduleByLink(String link) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'schedules',
      where: "link = ?",
      whereArgs: [link],
    );
    if (maps.isEmpty) {
      return null;
    }
    return ScheduleModel.fromJson(maps.first);
  }

  @override
  Future<List<ScheduleModel>> getAllSchedulesOnce() async {
    final db = await database;
    final maps = await db.query('schedules');
    return maps.map((e) => ScheduleModel.fromJson(e)).toList();
  }

  @override
  Future<void> refresh() async {
    await emitAllSchedules();
  }

  /// Releases the stream and the database handle.
  ///
  /// Idempotent: a second call is a no-op, so a caller that disposes early
  /// and a tear-down that disposes again both work.
  Future<void> dispose() async {
    if (!_controller.isClosed) await _controller.close();
    final db = _database;
    _database = null;
    await db?.close();
  }
}
