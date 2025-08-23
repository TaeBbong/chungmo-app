/// Step 5:
/// Data source
///
/// CRUD based data source implement with remote/local source

import 'dart:async';

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

  Stream<List<ScheduleModel>> get allSchedulesStream;

  Future<ScheduleModel?> getScheduleByLink(String link);

  Future<void> refresh();
}

@LazySingleton(as: ScheduleLocalSource)
class ScheduleLocalSourceImpl implements ScheduleLocalSource {
  static Database? _database;

  final _controller = StreamController<List<ScheduleModel>>.broadcast();

  @override
  Stream<List<ScheduleModel>> get allSchedulesStream => _controller.stream;

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
    final path = join(await getDatabasesPath(), 'schedule_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE schedules (
            link TEXT PRIMARY KEY,
            thumbnail TEXT,
            groom TEXT,
            bride TEXT,
            datetime TEXT,
            location TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // if (oldVersion < 2) {
        //   // UPDATE: 새로운 필드 추가 ('thumbnail')
        //   await db.execute('ALTER TABLE schedules ADD COLUMN thumbnail TEXT;');
        // }
      },
    );
  }

  @override
  Future<void> emitAllSchedules() async {
    final db = await database;
    final maps = await db.query('schedules');
    final list = maps.map((e) => ScheduleModel.fromJson(e)).toList();
    _controller.add(list);
  }

  @override
  Stream<List<ScheduleModel>> watchAllSchedules() {
    refresh();
    return _controller.stream;
  }

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
  Future<void> refresh() async {
    await emitAllSchedules();
  }

  void dispose() {
    _controller.close();
  }
}
