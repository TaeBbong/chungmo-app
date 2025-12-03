/// Step 5:
/// Data source
///
/// CRUD based data source implement with remote/local source

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:injectable/injectable.dart';

import '../../../core/env.dart';
import '../../../core/utils/constants.dart';
import '../../models/schedule/schedule_model.dart';

abstract class ScheduleRemoteSourceVertex {
  Future<ScheduleModel> fetchScheduleFromServer(String url);
}

@LazySingleton(as: ScheduleRemoteSourceVertex)
class ScheduleRemoteSourceImpl implements ScheduleRemoteSourceVertex {
  final Dio dio = Dio();

  ScheduleRemoteSourceImpl();

  /// Fetch analyzed data in `json` type from Firebase functions API.
  ///
  /// If result, returns `ScheduleModel` type data.
  ///
  /// If not, throw error.
  @override
  Future<ScheduleModel> fetchScheduleFromServer(String link) async {
    final Map<String, Object> responseJsonSchema = {};
    final model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
          responseJsonSchema: responseJsonSchema,
          responseMimeType: "application/json"),
    );
    final prompt = [Content.text("Do something with ...")];
    final response = await model.generateContent(prompt);

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
