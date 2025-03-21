/// Step 5:
/// Data source
///
/// CRUD based data source implement with remote/local source

import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../models/schedule/schedule_model.dart';

abstract class ScheduleLocalSource {
  /// Create `schedule` data row from model `ScheduleModel`.
  Future<void> saveSchedule(ScheduleModel schedule);

  /// Update `schedule` data row from updated instance type `ScheduleModel`.
  Future<void> editSchedule(ScheduleModel schedule);

  /// Retrieves all `schedules` in type `List<ScheduleModel>`.
  Future<List<ScheduleModel>> getAllSchedules();

  /// Retrieve a `schedule` in type `ScheduleModel` by key `link`.
  ///
  /// If no matching results, returns `null`.
  Future<ScheduleModel?> getScheduleByLink(String link);

  /// Retrieve monthly `schedules` in type `Map<DateTime, List<ScheduleModel>>` by key `DateTime date`.
  Future<Map<DateTime, List<ScheduleModel>>> getSchedulesForMonth(
      DateTime date);

  /// Deletes `schedule` from db by key `link`.
  Future<void> deleteScheduleByLink(String link);
}

@LazySingleton(as: ScheduleLocalSource)
class ScheduleLocalSourceImpl implements ScheduleLocalSource {
  static Database? _database;

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

  /// Create `schedule` data row from model `ScheduleModel`.
  @override
  Future<void> saveSchedule(ScheduleModel schedule) async {
    final db = await database;
    await db.insert(
      'schedules',
      schedule.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
  }

  /// Retrieves all `schedules` in type `List<ScheduleModel>`.
  @override
  Future<List<ScheduleModel>> getAllSchedules() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('schedules', orderBy: 'datetime');

    return List.generate(maps.length, (i) {
      return ScheduleModel.fromJson(maps[i]);
    });
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

  /// Retrieve monthly `schedules` in type `Map<DateTime, List<ScheduleModel>>` by key `DateTime date`.
  ///
  /// If no matching results, returns empty list `[]`.
  @override
  Future<Map<DateTime, List<ScheduleModel>>> getSchedulesForMonth(
      DateTime date) async {
    final db = await database;
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final lastDayOfMonth = DateTime(date.year, date.month + 1, 0);

    final List<Map<String, dynamic>> maps = await db.query(
      'schedules',
      where: "datetime BETWEEN ? AND ?",
      whereArgs: [
        firstDayOfMonth.toIso8601String(),
        lastDayOfMonth.toIso8601String(),
      ],
    );

    List<ScheduleModel> schedules =
        maps.map((map) => ScheduleModel.fromJson(map)).toList();
    Map<DateTime, List<ScheduleModel>> schedulesByDate = {};

    for (var schedule in schedules) {
      final scheduleDate = DateTime.parse(schedule.date);
      final normalizedDate =
          DateTime(scheduleDate.year, scheduleDate.month, scheduleDate.day);
      if (!schedulesByDate.containsKey(normalizedDate)) {
        schedulesByDate[normalizedDate] = [];
      }
      schedulesByDate[normalizedDate]!.add(schedule);
    }
    return schedulesByDate;
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
    return;
  }
}
