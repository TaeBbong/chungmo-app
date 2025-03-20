/// Step 6:
/// RepositoryImpl
///
/// Implementation of repository from domain layer
/// Implement each features of repository with data sources

import 'package:injectable/injectable.dart';

import '../../core/services/notification_service.dart';
import '../../domain/entities/schedule.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../mapper/schedule_mapper.dart';
import '../models/schedule/schedule_model.dart';
import '../sources/local/schedule_local_source.dart';
import '../sources/remote/schedule_remote_source.dart';

/// Implementation class for `ScheduleRepository`
@LazySingleton(as: ScheduleRepository)
class ScheduleRepositoryImpl implements ScheduleRepository {
  final ScheduleRemoteSource remoteSource;
  final ScheduleLocalSource localSource;
  final NotificationService notificationService;

  ScheduleRepositoryImpl(
      this.remoteSource, this.localSource, this.notificationService);

  @override
  Future<Schedule> analyzeLink(String url) async {
    try {
      final schedule = await remoteSource.fetchScheduleFromServer(url);
      Schedule entitySchedule = ScheduleMapper.toEntity(schedule);
      return entitySchedule;
    } catch (e) {
      throw Exception('[-] Error while fetching from server');
    }
  }

  @override
  Future<void> saveSchedule(Schedule schedule) async {
    final scheduleModel = ScheduleModel(
      link: schedule.link,
      thumbnail: schedule.thumbnail,
      groom: schedule.groom,
      bride: schedule.bride,
      date: schedule.date,
      location: schedule.location,
    );
    await localSource.saveSchedule(scheduleModel);
    await notificationService.checkPreviousDayForNotify(schedule: schedule);
  }

  @override
  Future<List<Schedule>> getSchedules() async {
    final List<ScheduleModel> schedules = await localSource.getAllSchedules();
    final List<Schedule> entitySchedules =
        schedules.map((e) => ScheduleMapper.toEntity(e)).toList();
    return entitySchedules;
  }

  @override
  Future<Schedule?> getScheduleByLink(String link) async {
    final ScheduleModel? scheduleModel =
        await localSource.getScheduleByLink(link);
    if (scheduleModel != null) {
      final Schedule schedule = ScheduleMapper.toEntity(scheduleModel);
      return schedule;
    }
    return null;
  }

  @override
  Future<Map<DateTime, List<Schedule>>> getSchedulesForMonth(
      DateTime date) async {
    final Map<DateTime, List<ScheduleModel>> schedulesWithDate =
        await localSource.getSchedulesForMonth(date);
    final Map<DateTime, List<Schedule>> entitySchedulesWithDate =
        schedulesWithDate.map(
      (key, value) => MapEntry(
        key,
        value.map((e) => ScheduleMapper.toEntity(e)).toList(),
      ),
    );
    return entitySchedulesWithDate;
  }

  @override
  Future<void> editSchedule(Schedule schedule) async {
    final scheduleModel = ScheduleModel(
        link: schedule.link,
        thumbnail: schedule.thumbnail,
        groom: schedule.groom,
        bride: schedule.bride,
        date: schedule.date,
        location: schedule.location);
    await localSource.editSchedule(scheduleModel);
    await notificationService.cancelNotifySchedule(link: schedule.link);
    await notificationService.checkPreviousDayForNotify(schedule: schedule);
  }

  @override
  Future<void> deleteSchedule(String link) async {
    await localSource.deleteScheduleByLink(link);
    await notificationService.cancelNotifySchedule(link: link);
  }
}
