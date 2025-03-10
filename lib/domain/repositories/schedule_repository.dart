/// Step 2:
/// Abstract model for repository
///
/// Only announce spec of methods that repository will implement.

import '../entities/schedule.dart';

abstract class ScheduleRepository {
  Future<Schedule> analyzeLink(String url);
  Future<void> saveSchedule(Schedule schedule);
  Future<List<Schedule>> getSchedules();
  Future<List<Schedule>> getSchedulesByDate(DateTime date);
  Future<Map<DateTime, List<Schedule>>> getSchedulesForMonth(DateTime date);
  Future<void> editSchedule(Schedule schedule);
  Future<void> deleteSchedule(String link);
}
