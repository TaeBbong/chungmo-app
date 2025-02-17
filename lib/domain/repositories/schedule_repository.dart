import '../entities/schedule.dart';

abstract class ScheduleRepository {
  Future<Schedule> analyzeLink(String url);
  Future<void> saveSchedule(Schedule schedule);
}