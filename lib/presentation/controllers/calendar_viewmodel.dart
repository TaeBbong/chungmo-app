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

  Rx<DateTime> focusedDay = DateTime.now().obs;
  Rx<DateTime> selectedDay = DateTime.now().obs;

  /// `schedulesWithDate` contains schedules filtered by month.
  var schedulesWithDate = Rxn<Map<DateTime, List<Schedule>>>();

  /// `allSchedules` contains whole schedules from db.
  var allSchedules = Rxn<List<Schedule>>();

  @override
  void onClose() {
    // TODO: why close for states??
  }

  void onDaySelected(DateTime selected, DateTime focused) {
    focusedDay.value = selected;
    selectedDay.value = selected;
  }

  void onPageChanged(DateTime focused) {
    focusedDay.value = focused;
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

  Future<void> onUpdateSchedule({required Schedule updatedSchedule}) async {
    // Step 1. Update focusedDay, selectedDay for CalendarView.
    focusedDay.value = DateTime.parse(updatedSchedule.date);
    selectedDay.value = DateTime.parse(updatedSchedule.date);

    // Step 2. Update `allSchedules` by key `link`.
    final currentList = allSchedules.value ?? [];
    final updatedList = currentList.map((s) {
      if (s.link == updatedSchedule.link) {
        return updatedSchedule;
      }
      return s;
    }).toList();
    allSchedules.value = updatedList;

    // Step 3. Update `schedulesWithDate` from updated `allSchedules`.
    DateTime normalizeDate(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

    final Map<DateTime, List<Schedule>> updatedMap = {};
    final DateTime targetMonth = DateTime(
        DateTime.parse(updatedSchedule.date).year,
        DateTime.parse(updatedSchedule.date).month);

    for (final schedule in allSchedules.value!) {
      final dateKey = normalizeDate(DateTime.parse(schedule.date));
      final DateTime scheduleMonth = DateTime(dateKey.year, dateKey.month);
      if (scheduleMonth == targetMonth) {
        if (!updatedMap.containsKey(dateKey)) {
          updatedMap[dateKey] = [];
        }
        updatedMap[dateKey]!.add(schedule);
      }
    }
    schedulesWithDate.value = updatedMap;
  }
}
