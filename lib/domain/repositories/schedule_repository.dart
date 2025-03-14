/// Step 2:
/// Abstract model for repository
///
/// Only announce spec of methods that repository will implement.

import '../entities/schedule.dart';

abstract class ScheduleRepository {
  /// Request to remote server with user input string `url`,
  ///
  /// Response `schedule` json data.
  Future<Schedule> analyzeLink(String url);

  /// Save Schedule `schedule` into local sqflite db by type ScheduleModel.
  ///
  /// Add notify schedule if `date` is after today.
  Future<void> saveSchedule(Schedule schedule);

  /// Get all `schedules` from local sqflite db for `ListView`
  Future<List<Schedule>> getSchedules();

  /// [NEED TO REMOVE]
  ///
  /// Get `schedule` by DateTime `date`.
  Future<List<Schedule>> getSchedulesByDate(DateTime date);

  /// Get monthly `schedules` from local sqflite db for `CalendarView`
  Future<Map<DateTime, List<Schedule>>> getSchedulesForMonth(DateTime date);

  /// Edit `schedule` from local sqflite db.
  ///
  /// Change notify schedule if `date` changed.
  Future<void> editSchedule(Schedule schedule);

  /// Delete `schedule` from local sqflite db.
  ///
  /// Delete notify schedule.
  Future<void> deleteSchedule(String link);
}
