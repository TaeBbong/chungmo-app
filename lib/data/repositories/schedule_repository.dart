/// Step 6:
/// RepositoryImpl
/// 
/// Implementation of repository from domain layer
/// Implement each features of repository with data sources


import 'package:injectable/injectable.dart';

import '../../domain/entities/schedule.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../mapper/schedule_mapper.dart';
import '../models/schedule/schedule_model.dart';
import '../sources/local/schedule_local_source.dart';
import '../sources/remote/schedule_remote_source.dart';

@LazySingleton(as: ScheduleRepository)
class ScheduleRepositoryImpl implements ScheduleRepository {
  final ScheduleRemoteSource remoteSource;
  final ScheduleLocalSource localSource;

  ScheduleRepositoryImpl(this.remoteSource, this.localSource);

  @override
  Future<Schedule> analyzeLink(String url) async {
    final schedule = await remoteSource.fetchScheduleFromServer(url);
    Schedule entitySchedule = ScheduleMapper.toEntity(schedule);
    return entitySchedule;
  }

  @override
  Future<void> saveSchedule(Schedule schedule) async {
    final scheduleModel = ScheduleModel(
      id: schedule.id,
      link: schedule.link,
      thumbnail: schedule.thumbnail,
      groom: schedule.groom,
      bride: schedule.bride,
      date: schedule.date,
      location: schedule.location,
    );
    await localSource.saveSchedule(scheduleModel);
  }

  @override
  Future<List<Schedule>> getSchedules() async {
    final List<ScheduleModel> schedules = await localSource.getSchedules();
    final List<Schedule> entitySchedules = schedules.map((e) => ScheduleMapper.toEntity(e)).toList();
    return entitySchedules;
  }

  @override
  Future<List<Schedule>> getSchedulesByDate(DateTime date) async {
    final List<ScheduleModel> schedules = await localSource.getSchedulesByDate(date);
    final List<Schedule> entitySchedules = schedules.map((e) => ScheduleMapper.toEntity(e)).toList();
    return entitySchedules;
  }

  @override
Future<Map<DateTime, List<Schedule>>> getSchedulesForMonth(DateTime date) async {
  final Map<DateTime, List<ScheduleModel>> schedulesWithDate = await localSource.getSchedulesForMonth(date);
  final Map<DateTime, List<Schedule>> entitySchedulesWithDate = schedulesWithDate.map(
    (key, value) => MapEntry(
      key,
      value.map((e) => ScheduleMapper.toEntity(e)).toList(),
    ),
  );
  return entitySchedulesWithDate;
}

}