/// Step 5:
/// Data source
/// 
/// CRUD based data source implement with remote/local source


import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../models/schedule/schedule_model.dart';

abstract class ScheduleLocalSource {
  Future<void> saveSchedule(ScheduleModel schedule);
  Future<List<ScheduleModel>> getSchedules();
  Future<List<ScheduleModel>> searchSchedule(String query);
  Future<List<ScheduleModel>> getSchedulesByDate(DateTime date);
  Future<Map<DateTime, List<ScheduleModel>>> getSchedulesForMonth(DateTime date);

}

@LazySingleton(as: ScheduleLocalSource)
class ScheduleLocalSourceImpl implements ScheduleLocalSource {
  static Database? _database;

  /// 📌 데이터베이스 초기화
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'schedule_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE schedules (
            id TEXT PRIMARY KEY,
            link TEXT,
            groom TEXT,
            bride TEXT,
            date TEXT
          )
        ''');
      },
    );
  }

  /// 📌 일정 저장
  @override
  Future<void> saveSchedule(ScheduleModel schedule) async {
    final db = await database;
    await db.insert(
      'schedules',
      schedule.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 📌 일정 불러오기
  @override
  Future<List<ScheduleModel>> getSchedules() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('schedules');

    return List.generate(maps.length, (i) {
      return ScheduleModel.fromJson(maps[i]);
    });
  }

  /// 📌 특정 필드 기반 검색
  @override
  Future<List<ScheduleModel>> searchSchedule(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'schedules',
      where: "groom LIKE ? OR bride LIKE ?",
      whereArgs: ['%$query%', '%$query%'],
    );

    return maps.map((map) => ScheduleModel.fromJson(map)).toList();
  }

  @override
  Future<List<ScheduleModel>> getSchedulesByDate(DateTime date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'schedules',
      where: "date = ?",
      whereArgs: [date.toIso8601String()],
    );
    return maps.map((map) => ScheduleModel.fromJson(map)).toList();
  }

  @override
  Future<Map<DateTime, List<ScheduleModel>>> getSchedulesForMonth(DateTime date) async {
    final db = await database;
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final lastDayOfMonth = DateTime(date.year, date.month + 1, 0);

    final List<Map<String, dynamic>> maps = await db.query(
      'schedules',
      where: "date BETWEEN ? AND ?",
      whereArgs: [
        firstDayOfMonth.toIso8601String(),
        lastDayOfMonth.toIso8601String(),
      ],
    );

    List<ScheduleModel> schedules = maps.map((map) => ScheduleModel.fromJson(map)).toList();
    Map<DateTime, List<ScheduleModel>> schedulesByDate = {};

    for (var schedule in schedules) {
      final scheduleDate = DateTime(schedule.date.year, schedule.date.month, schedule.date.day);
      if (!schedulesByDate.containsKey(scheduleDate)) {
        schedulesByDate[scheduleDate] = [];
      }
      schedulesByDate[scheduleDate]!.add(schedule);
    }
    return schedulesByDate;
  }

}
