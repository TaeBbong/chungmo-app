/// Step 5:
/// Data source
///
/// CRUD based data source implement with remote/local source

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/env.dart';
import '../../../core/utils/constants.dart';
import '../../models/schedule/schedule_model.dart';
import 'schedule_remote_source.dart';

@LazySingleton(as: ScheduleRemoteSource, env: ['cloud'])
class CloudFunctionImpl implements ScheduleRemoteSource {
  final Dio dio = Dio();

  CloudFunctionImpl();

  /// Fetch analyzed data in `json` type from Firebase functions API.
  ///
  /// If result, returns `ScheduleModel` type data.
  ///
  /// If not, throw error.
  @override
  Future<ScheduleModel> fetchScheduleFromServer(String link) async {
    try {
      final response = await dio.post('${Env.url}/', data: {'link': link});
      if (response.statusCode == 200) {
        ScheduleModel model = ScheduleModel.fromJson(
            jsonDecode(response.data)..addAll({'link': link}));
        if (model.thumbnail.isEmpty) {
          model = model.copyWith(thumbnail: Constants.defaultThumbnail);
        }
        return model;
      } else {
        throw Exception('[-] Failed to fetch data from server');
      }
    } catch (e) {
      throw Exception('[-] Failed to fetch data from server');
    }
  }
}
