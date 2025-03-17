/// Step 7:
/// Controllers(viewmodel)
///
/// Implementation of controllers that receive data from usecase,
/// control states for pages

import 'package:flutter/material.dart';

import '../../core/di/di.dart';
import 'package:get/get.dart';

import '../../domain/entities/schedule.dart';
import '../../domain/usecases/schedule/list_schedules_by_date_usecase.dart';
import '../../domain/usecases/schedule/list_schedules_usecase.dart';

class CalendarController extends GetxController {
  final ListSchedulesByDateUsecase listSchedulesByDateUsecase =
      getIt<ListSchedulesByDateUsecase>();
  final ListSchedulesUsecase listSchedulesUsecase =
      getIt<ListSchedulesUsecase>();

  /// `isLoading` checks if getSchedules*() from local data source is running.
  var isLoading = false.obs;

  /// `schedulesWithDate` contains schedules filtered by month.
  var schedulesWithDate = Rxn<Map<DateTime, List<Schedule>>>();

  /// `allSchedules` contains whole schedules from db.
  var allSchedules = Rxn<List<Schedule>>();

  @override
  void onClose() {
    isLoading.close();
    schedulesWithDate.close();
    super.onClose();
  }

  /// `getSchedulesForMonth` executes `listSchedulesByDateUsecase`
  /// then updates `schedulesWithDate`.
  Future<void> getSchedulesForMonth(DateTime date) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isLoading(true);
    });
    schedulesWithDate.value = await listSchedulesByDateUsecase.execute(date);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isLoading(false);
    });
    return;
  }

  /// `getAllSchedules` executes `listSchedulesUsecase`
  /// then updates `allSchedules`.
  Future<void> getAllSchedules() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isLoading(true);
    });
    allSchedules.value = await listSchedulesUsecase.execute();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isLoading(false);
    });
    return;
  }
}
