/// Step 7:
/// Controllers(viewmodel)
///
/// Implementation of controllers that receive data from usecase,
/// control states for pages

import 'dart:async';

import 'package:get/get.dart';

import '../../core/di/di.dart';
import '../../domain/entities/schedule.dart';
import '../../domain/usecases/usecases.dart';

class CalendarController extends GetxController {
  final WatchAllSchedulesUsecase watchAllSchedulesUsecase =
      getIt<WatchAllSchedulesUsecase>();

  /// `isLoading` checks if getSchedules*() from local data source is running.
  var isLoading = false.obs;

  Rx<DateTime> focusedDay = DateTime.now().obs;
  Rx<DateTime> selectedDay = DateTime.now().obs;

  RxList<Schedule> allSchedules = <Schedule>[].obs;
  RxMap<DateTime, List<Schedule>> currentMonthSchedules =
      <DateTime, List<Schedule>>{}.obs;

  StreamSubscription? _allSub;

  @override
  void onInit() {
    listenAllSchedules();
    _groupSchedulesForMonth(focusedDay.value);
    super.onInit();
  }

  void onDaySelected(DateTime selected, DateTime focused) {
    focusedDay.value = selected;
    selectedDay.value = selected;
    _groupSchedulesForMonth(selected);
  }

  void onPageChanged(DateTime focused) {
    focusedDay.value = focused;
    _groupSchedulesForMonth(focused);
  }

  void listenAllSchedules() {
    _allSub?.cancel();
    _allSub = watchAllSchedulesUsecase.execute().listen((list) {
      allSchedules.value = list;
      _groupSchedulesForMonth(focusedDay.value);
    });
  }

  void _groupSchedulesForMonth(DateTime month) {
    final Map<DateTime, List<Schedule>> grouped = {};
    for (final s in allSchedules) {
      if (s.date.year == month.year && s.date.month == month.month) {
        final key = DateTime(s.date.year, s.date.month, s.date.day);
        grouped.putIfAbsent(key, () => []).add(s);
      }
    }
    currentMonthSchedules.value = grouped;
  }

  @override
  void onClose() {
    _allSub?.cancel();
    super.onClose();
  }
}
