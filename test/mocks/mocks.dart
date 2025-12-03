import 'package:chungmo/data/sources/remote/schedule_remote_source.dart';
import 'package:chungmo/domain/usecases/usecases.dart';
import 'package:chungmo/presentation/bloc/create/create_cubit.dart';
import 'package:mockito/annotations.dart';
import 'package:chungmo/data/sources/local/schedule_local_source.dart';
import 'package:chungmo/core/services/notification_service.dart';

@GenerateMocks([
  ScheduleLocalSource,
  ScheduleRemoteSource,
  NotificationService,
  AnalyzeLinkUsecase,
  SaveScheduleUsecase,
  CreateCubit,
])
void main() {}
