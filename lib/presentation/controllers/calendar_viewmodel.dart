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

  var isLoading = false.obs;
  var schedulesWithDate = Rxn<Map<DateTime, List<Schedule>>>();
  var allSchedules = Rxn<List<Schedule>>();

  @override
  void onClose() {
    isLoading.close();
    schedulesWithDate.close();
    super.onClose();
  }

  Future<Map<DateTime, List<Schedule>>> getSchedulesForMonth(
      DateTime date) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isLoading(true);
    });
    schedulesWithDate.value = await listSchedulesByDateUsecase.execute(date);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isLoading(false);
    });
    return schedulesWithDate.value!;
  }

  List<Schedule> getAllSchedulesForMonth() {
    final schedulesMap = schedulesWithDate.value ?? {};
    return schedulesMap.values.expand((schedules) => schedules).toList();
  }

  Future<List<Schedule>> getAllSchedules() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isLoading(true);
    });
    allSchedules.value = await listSchedulesUsecase.execute();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isLoading(false);
    });
    return allSchedules.value!;
  }
}
