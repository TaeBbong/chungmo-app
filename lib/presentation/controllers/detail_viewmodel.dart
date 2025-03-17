import 'package:get/get.dart';

import '../../core/di/di.dart';
import '../../domain/entities/schedule.dart';
import '../../domain/usecases/schedule/delete_schedule_usecase.dart';
import '../../domain/usecases/schedule/edit_schedule_usecase.dart';

class DetailController extends GetxController {
  final EditScheduleUsecase editScheduleUsecase = getIt<EditScheduleUsecase>();
  final DeleteScheduleUsecase deleteScheduleUsecase =
      getIt<DeleteScheduleUsecase>();

  /// `schedule` is entity that currently watching in `DetailPage`.
  var schedule = Rxn<Schedule>();

  /// `editSchedule` copies `editedSchedule` to `schedule`
  /// then executes `editScheduleUsecase`.
  Future<void> editSchedule(Schedule editedSchedule) async {
    schedule.value = schedule.value!.copyWith(
        bride: editedSchedule.bride,
        groom: editedSchedule.groom,
        date: editedSchedule.date,
        location: editedSchedule.location);
    await editScheduleUsecase.execute(schedule.value!);
  }

  /// `deleteSchedule` deletes schedule within key `link`
  /// executes `deleteScheduleUsecase`.
  Future<void> deleteSchedule(String link) async {
    await deleteScheduleUsecase.execute(link);
  }
}
