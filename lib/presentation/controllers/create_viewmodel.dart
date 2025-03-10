/// Step 7:
/// Controllers(viewmodel)
///
/// Implementation of controllers that receive data from usecase,
/// control states for pages

import '../../core/di/di.dart';
import 'package:get/get.dart';

import '../../domain/entities/schedule.dart';
import '../../domain/usecases/schedule/analyze_link_usecase.dart';
import '../../domain/usecases/schedule/save_schedule_usecase.dart';

class CreateController extends GetxController {
  final AnalyzeLinkUsecase analyzeLinkUseCase = getIt<AnalyzeLinkUsecase>();
  final SaveScheduleUsecase saveScheduleUseCase = getIt<SaveScheduleUsecase>();

  var isLoading = false.obs;
  var schedule = Rxn<Schedule>();

  // TODO: 잘 로드되었는지 확인하는 state 필요, 제대로 로드되지 않으면 위젯에서 실패 표시
  Future<void> analyzeLink(String url) async {
    isLoading(true);
    schedule.value = await analyzeLinkUseCase.execute(url);
    isLoading(false);

    await saveScheduleUseCase.execute(schedule.value!);
  }

  void resetState() {
    isLoading.value = false;
    schedule.value = null;
  }
}
