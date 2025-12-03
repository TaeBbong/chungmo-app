/// Step 5:
/// Data source
///
/// CRUD based data source implement with remote/local source

import 'dart:convert';

import 'package:chungmo/core/utils/crawler.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:injectable/injectable.dart';

import '../../../core/utils/constants.dart';
import '../../models/schedule/schedule_model.dart';
import 'schedule_remote_source.dart';

@LazySingleton(as: ScheduleRemoteSource, env: ['firebase'])
class FirebaseAiLogicImpl implements ScheduleRemoteSource {
  FirebaseAiLogicImpl();

  /// Fetch analyzed data in `json` type from Firebase AI Logic.
  ///
  /// If result, returns `ScheduleModel` type data.
  ///
  /// If not, throw error.
  @override
  Future<ScheduleModel> fetchScheduleFromServer(String link) async {
    final Map<String, Object> responseJsonSchema = {
      "type": "object",
      "title": "ScheduleResponse",
      "description": "ScheduleResponse from Gemini-2.5 parsed invitation",
      "properties": {
        "thumbnail": {
          "type": "string",
          "description": "Thumbnail link from response",
        },
        "groom": {
          "type": "string",
          "description": "Name of groom from response",
        },
        "bride": {
          "type": "string",
          "description": "Name of bride from response",
        },
        "location": {
          "type": "string",
          "description": "Event location from response",
        },
        "datetime": {
          "type": "string",
          "format": "date-time",
          "description":
              "ISO 8601 date-time, in UTC+9(kst), e.g. 2025-12-02T10:30:00+09:00"
        }
      }
    };
    final model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
          responseJsonSchema: responseJsonSchema,
          responseMimeType: "application/json"),
    );
    try {
      final parsed = await extractContentWithImages(link);
      final prompt = [
        Content.text(
            '''Extract the required wedding data from the given text and return it in pure JSON format, without any additional text or snippet tags.
          Required data's are:
          thumbnail, groom, bride, location, datetime
          If you can't find proper data, just put empty string for that field.

          Given text:
          $parsed
          ''')
      ];
      final response = await model.generateContent(prompt);
      if (response.text != null) {
        ScheduleModel model = ScheduleModel.fromJson(
            jsonDecode(response.text!)..addAll({'link': link}));
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
