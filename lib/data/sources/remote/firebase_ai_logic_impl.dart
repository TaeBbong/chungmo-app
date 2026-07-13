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

/// JSON schema of a single 축의금 account, shared by both sides.
const Map<String, Object> _accountJsonSchema = {
  "type": "object",
  "properties": {
    "bank": {"type": "string", "description": "Bank name, e.g. 국민"},
    "number": {
      "type": "string",
      "description": "Account number including hyphens, e.g. 123-45-6789"
    },
    "holder": {"type": "string", "description": "Account holder name"},
    "relation": {
      "type": "string",
      "description":
          "Relation of the holder, one of 신랑, 신부, 아버지, 어머니. Empty if unknown."
    }
  }
};

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
        },
        "groomAccounts": {
          "type": "array",
          "description": "Gift money accounts of the groom's side",
          "items": _accountJsonSchema,
        },
        "brideAccounts": {
          "type": "array",
          "description": "Gift money accounts of the bride's side",
          "items": _accountJsonSchema,
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
          thumbnail, groom, bride, location, datetime, groomAccounts, brideAccounts
          If you can't find proper data, just put empty string for that field.

          groomAccounts/brideAccounts are the gift money(축의금) accounts, usually
          written under a section like "마음 전하실 곳" or "축의금 계좌".
          Each account has a bank name, an account number, a holder name and the
          holder's relation(신랑, 신부, 아버지, 어머니). Group them by side: the groom's
          side(신랑측, including his parents) into groomAccounts, the bride's side
          (신부측, including her parents) into brideAccounts.
          If no account is found for a side, return an empty array for it.

          Given text:
          $parsed
          ''')
      ];
      final response = await model.generateContent(prompt);
      if (response.text != null) {
        ScheduleModel model =
            ScheduleModel.fromJson(_toModelJson(response.text!, link));
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

  /// Adapts the Gemini response into `ScheduleModel`'s json shape:
  /// the account arrays are re-encoded as strings, since they are persisted
  /// into single TEXT columns.
  Map<String, dynamic> _toModelJson(String responseText, String link) {
    final json = jsonDecode(responseText) as Map<String, dynamic>;
    return {
      ...json,
      'link': link,
      'groom_accounts': jsonEncode(json['groomAccounts'] ?? []),
      'bride_accounts': jsonEncode(json['brideAccounts'] ?? []),
    };
  }
}
