/// Step 3:
/// Usecase
///
/// Pass data by running business logic using abstract repository

import 'package:injectable/injectable.dart';

import '../../core/base/base_usecase.dart';
import '../../core/utils/image_preprocessor.dart';
import '../entities/invitation_image.dart';
import '../entities/schedule.dart';
import '../repositories/schedule_repository.dart';

@injectable
class AnalyzeImageUsecase
    implements ParamUsecase<InvitationImage, Future<Schedule>> {
  final ScheduleRepository repository;

  AnalyzeImageUsecase(this.repository);

  @override
  Future<Schedule> execute(InvitationImage image) async {
    // Downscaling lives here, on the single entry point for image parses,
    // so every caller gets the same preprocessing; the picker path is a
    // cheap pass-through (already ≤ 1600px).
    return repository.analyzeImage(await ImagePreprocessor.downscale(image));
  }
}
