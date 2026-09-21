/// Step 6:
/// RepositoryImpl
///
/// Implementation of repository from domain layer
/// Implement each features of repository with data sources

import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../core/services/notification_service.dart';
import '../../core/utils/image_preprocessor.dart';
import '../../domain/entities/invitation_image.dart';
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
    } on FormatException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (e) {
      throw Exception('[-] Error while fetching from server: $e');
    }
  }

  @override
  Future<Schedule> analyzeImage(InvitationImage image) async {
    try {
      // Downscaling lives here so every caller of the image parse gets the
      // same preprocessing; the picker path is a cheap pass-through
      // (already ≤ 1600px). The data layer already runs this flow's other
      // isolate work (the image key hash), so the Flutter dependency stays
      // out of the domain.
      final InvitationImage prepared = await ImagePreprocessor.downscale(image);
      final schedule = await remoteSource.fetchScheduleFromImage(
          prepared.bytes, prepared.mimeType);
      Schedule entitySchedule = ScheduleMapper.toEntity(schedule);
      return entitySchedule;
    } on FormatException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (e) {
      throw Exception('[-] Error while fetching from server: $e');
    }
  }

  @override
  Future<Schedule> analyzeText(String text) async {
    try {
      final schedule = await remoteSource.fetchScheduleFromText(text);
      Schedule entitySchedule = ScheduleMapper.toEntity(schedule);
      return entitySchedule;
    } on FormatException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (e) {
      throw Exception('[-] Error while fetching from server: $e');
    }
  }

  @override
  Future<void> saveSchedule(Schedule schedule) async {
    ScheduleModel scheduleModel = ScheduleMapper.toModel(schedule);
    await localSource.saveSchedule(scheduleModel);
    await notificationService.checkPreviousDayForNotify(schedule: schedule);
  }

  @override
  Stream<List<Schedule>> getAllSchedules() {
    return localSource.watchAllSchedules().map(
          (list) => list.map(ScheduleMapper.toEntity).toList(),
        );
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
  Future<void> editSchedule(Schedule schedule) async {
    ScheduleModel scheduleModel = ScheduleMapper.toModel(schedule);
    await localSource.editSchedule(scheduleModel);
    await notificationService.cancelNotifySchedule(link: schedule.link);
    await notificationService.checkPreviousDayForNotify(schedule: schedule);
  }

  @override
  Future<void> deleteSchedule(String link) async {
    await localSource.deleteScheduleByLink(link);
    await notificationService.cancelNotifySchedule(link: link);
  }

  /// Caps one backfill batch; more than this in one household is unheard of.
  static const int _maxBackfillLocations = 50;

  @override
  Future<void> backfillVenues() async {
    final DateTime today = DateTime.now();
    final DateTime midnight = DateTime(today.year, today.month, today.day);
    // Only upcoming schedules matter: past rows never open the map again,
    // and skipping them keeps the batch (and the prompt) small.
    final List<ScheduleModel> candidates =
        (await localSource.getAllSchedulesOnce())
            .where((m) =>
                m.venue.isEmpty &&
                m.location.trim().isNotEmpty &&
                (DateTime.tryParse(m.date)?.isAfter(midnight) ?? false))
            .toList();
    if (candidates.isEmpty) return;

    final List<String> locations = candidates
        .map((m) => m.location.trim())
        .toSet()
        .take(_maxBackfillLocations)
        .toList();
    final Map<String, String> venues =
        await remoteSource.extractVenues(locations);
    if (venues.isEmpty) return;

    var updated = 0;
    for (final model in candidates) {
      final String? venue = venues[model.location.trim()];
      if (venue == null || venue.isEmpty) continue;
      await localSource.editSchedule(model.copyWith(venue: venue));
      updated++;
    }
    // One emission at the end: the home preview, calendar and widget all
    // watch this stream and pick the new venues up together.
    if (updated > 0) await localSource.emitAllSchedules();
  }
}
