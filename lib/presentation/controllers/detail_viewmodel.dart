import '../../core/di/di.dart';
import 'package:get/get.dart';

import '../../domain/entities/schedule.dart';
import '../../domain/usecases/schedule/edit_schedule_usecase.dart';

class DetailController extends GetxController {
  final EditScheduleUsecase editScheduleUsecase = getIt<EditScheduleUsecase>();

  var schedule = Rxn<Schedule>();

  Future<void> editSchedule(Schedule editedSchedule) async {
    schedule.value = schedule.value!.copyWith(
        bride: editedSchedule.bride,
        groom: editedSchedule.groom,
        date: editedSchedule.date,
        location: editedSchedule.location);
    await editScheduleUsecase.execute(schedule.value!);
  }
}
