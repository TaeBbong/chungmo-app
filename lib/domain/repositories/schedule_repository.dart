/// Step 2:
/// Abstract model for repository
///
/// Only announce spec of methods that repository will implement.

import '../entities/invitation_image.dart';
import '../entities/schedule.dart';

abstract class ScheduleRepository {
  /// Request to remote server with user input string `url`,
  ///
  /// Response `schedule` json data.
  Future<Schedule> analyzeLink(String url);

  /// Request to remote server with an invitation `image`,
  ///
  /// Response `schedule` json data keyed by a synthetic `image://` link.
  Future<Schedule> analyzeImage(InvitationImage image);

  /// Request to remote server with pasted invitation `text`,
  ///
  /// Response `schedule` json data keyed by a synthetic `text://` link.
  Future<Schedule> analyzeText(String text);

  /// Save Schedule `schedule` into local sqflite db by type ScheduleModel.
  ///
  /// Add notify schedule if `date` is after today.
  Future<void> saveSchedule(Schedule schedule);

  Stream<List<Schedule>> getAllSchedules();

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
