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
  final WatchSchedulesForMonthUsecase watchMonthUsecase =
      getIt<WatchSchedulesForMonthUsecase>();

  /// `isLoading` checks if getSchedules*() from local data source is running.
  var isLoading = false.obs;

  Rx<DateTime> focusedDay = DateTime.now().obs;
  Rx<DateTime> selectedDay = DateTime.now().obs;

  /// `schedulesWithDate` contains schedules filtered by month.
  // var schedulesWithDate = Rxn<Map<DateTime, List<Schedule>>>();

  RxList<Schedule> allSchedules = <Schedule>[].obs;
  RxMap<DateTime, List<Schedule>> currentMonthSchedules =
      <DateTime, List<Schedule>>{}.obs;

  StreamSubscription? _allSub;
  StreamSubscription? _monthSub;

  RxMap<DateTime, List<Schedule>> schedulesWithDate =
      <DateTime, List<Schedule>>{}.obs;

  @override
  void onInit() {
    listenAllSchedules();
    listenSchedulesForMonth(focusedDay.value);
    super.onInit();
  }

  void onDaySelected(DateTime selected, DateTime focused) {
    focusedDay.value = selected;
    selectedDay.value = selected;
    listenSchedulesForMonth(selected);
  }

  void onPageChanged(DateTime focused) {
    focusedDay.value = focused;
    listenSchedulesForMonth(focused);
  }

  void listenAllSchedules() {
    _allSub?.cancel();
    _allSub = watchAllSchedulesUsecase.execute().listen((list) {
      allSchedules.value = list;
    });
  }

  void listenSchedulesForMonth(DateTime month) {
    _monthSub?.cancel();
    _monthSub = watchMonthUsecase.execute(month).listen((map) {
      currentMonthSchedules.value = map;
    });
  }

  @override
  void onClose() {
    _allSub?.cancel();
    _monthSub?.cancel();
    super.onClose();
  }
}
