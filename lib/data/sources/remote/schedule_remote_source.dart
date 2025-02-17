import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../models/schedule/schedule_model.dart';

abstract class ScheduleRemoteSource {
  Future<ScheduleModel> fetchScheduleFromServer(String url);
}

@LazySingleton(as: ScheduleRemoteSource)
class ScheduleRemoteSourceImpl implements ScheduleRemoteSource {
  final Dio dio = Dio();

  ScheduleRemoteSourceImpl();

  @override
  Future<ScheduleModel> fetchScheduleFromServer(String link) async {
    final response = await dio.post('https://api.example.com/analyze', data: {'link': link});

    if (response.statusCode == 200) {
      return ScheduleModel.fromJson(response.data);
    } else {
      throw Exception('[-] Failed to fetch data from server');
    }
  }
}