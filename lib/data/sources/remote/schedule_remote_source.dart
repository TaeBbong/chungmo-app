import '../../models/schedule/schedule_model.dart';

abstract class ScheduleRemoteSource {
  Future<ScheduleModel> fetchScheduleFromServer(String url);
}
