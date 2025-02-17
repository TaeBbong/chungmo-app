import 'package:get/get.dart';

import '../../domain/entities/schedule.dart';
import '../../domain/usecases/schedule/analyze_link_usecase.dart';
import '../../domain/usecases/schedule/save_schedule_usecase.dart';

class CreateController extends GetxController {
  final AnalyzeLinkUsecase analyzeLinkUseCase;
  final SaveScheduleUsecase saveScheduleUseCase;

  var isLoading = false.obs;
  var schedule = Rxn<Schedule>();

  CreateController(this.analyzeLinkUseCase, this.saveScheduleUseCase);

  Future<void> analyzeLink(String url) async {
    isLoading(true);
    schedule.value = await analyzeLinkUseCase.execute(url);
    isLoading(false);

    await saveScheduleUseCase.execute(schedule.value!);
  }
}
