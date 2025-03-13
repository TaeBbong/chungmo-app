import 'package:mockito/annotations.dart';
import 'package:chungmo/data/sources/local/schedule_local_source.dart';
import 'package:chungmo/data/sources/remote/schedule_remote_source.dart';
import 'package:chungmo/core/services/notification_service.dart';

@GenerateMocks([
  ScheduleLocalSource,
  ScheduleRemoteSource,
  NotificationService,
])
void main() {}
