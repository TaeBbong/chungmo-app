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

  Stream<List<Schedule>> getAllSchedules();

  Stream<Map<DateTime, List<Schedule>>> getSchedulesGroupedByDate();

  /// Get monthly `schedules` from local sqflite db for `CalendarView`
  Stream<Map<DateTime, List<Schedule>>> getSchedulesForMonth(DateTime month);

  /// Get a `schedule` from local sqflite db by key `link` for routing `/detail`.
  Future<Schedule?> getScheduleByLink(String link);

  /// Edit `schedule` from local sqflite db.
  ///
  /// Change notify schedule if `date` changed.
  Future<void> editSchedule(Schedule schedule);

  /// Delete `schedule` from local sqflite db.
  ///
  /// Delete notify schedule.
  Future<void> deleteSchedule(String link);
}
