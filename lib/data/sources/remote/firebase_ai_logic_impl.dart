/// Step 5:
/// Data source
///
/// CRUD based data source implement with remote/local source

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:chungmo/core/utils/crawler.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:injectable/injectable.dart';

import '../../../core/utils/constants.dart';
import '../../../core/utils/string_extension.dart';
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

/// Response schema shared by the link and image parsers.
const Map<String, Object> _responseJsonSchema = {
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

/// Field guidelines shared by the link and image extraction prompts.
const String _extractionGuidelines = '''Required data's are:
thumbnail, groom, bride, location, datetime, groomAccounts, brideAccounts
If you can't find proper data, just put empty string for that field.

groomAccounts/brideAccounts are the gift money(축의금) accounts, usually
written under a section like "마음 전하실 곳" or "축의금 계좌".
Each account has a bank name, an account number, a holder name and the
holder's relation(신랑, 신부, 아버지, 어머니). Group them by side: the groom's
side(신랑측, including his parents) into groomAccounts, the bride's side
(신부측, including her parents) into brideAccounts.
If no account is found for a side, return an empty array for it.''';

@LazySingleton(as: ScheduleRemoteSource, env: ['firebase'])
class FirebaseAiLogicImpl implements ScheduleRemoteSource {
  FirebaseAiLogicImpl();

  GenerativeModel _buildModel() {
    return FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
          responseJsonSchema: _responseJsonSchema,
          responseMimeType: "application/json"),
    );
  }

  /// Fetch analyzed data in `json` type from Firebase AI Logic.
  ///
  /// If result, returns `ScheduleModel` type data.
  ///
  /// If not, throw error.
  @override
  Future<ScheduleModel> fetchScheduleFromServer(String link) async {
    try {
      final parsed = await extractContentWithImages(link);
      final prompt = [
        Content.text(
            '''Extract the required wedding data from the given text and return it in pure JSON format, without any additional text or snippet tags.
          $_extractionGuidelines

          Given text:
          $parsed
          ''')
      ];
      return await _generate(prompt, link);
    } on FormatException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (e) {
      throw Exception('[-] Failed to fetch data from server: $e');
    }
  }

  /// Parse a wedding invitation image with Gemini's multimodal input.
  ///
  /// The stored `link` is a content-addressed `image://<hash>` id, so
  /// re-submitting the same image maps to the same schedule.
  @override
  Future<ScheduleModel> fetchScheduleFromImage(
      Uint8List bytes, String mimeType) async {
    try {
      final String syntheticLink =
          'image://${await base64Encode(bytes).hashUrl}';
      final prompt = [
        Content.multi([
          const TextPart(
              '''Extract the required wedding data from the given wedding invitation image and return it in pure JSON format, without any additional text or snippet tags.
          The image is usually a screenshot of a mobile wedding invitation or a
          photo of a paper invitation, written in Korean.
          $_extractionGuidelines
          Put an empty string for thumbnail; an image has no thumbnail URL.
          '''),
          InlineDataPart(mimeType, bytes),
        ])
      ];
      return await _generate(prompt, syntheticLink);
    } on FormatException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (e) {
      throw Exception('[-] Failed to fetch data from server: $e');
    }
  }

  /// Parse invitation text the user pasted directly (SMS, 카톡 message).
  ///
  /// Same extraction as the link parser, minus the crawling step. The stored
  /// `link` is a content-addressed `text://<hash>` id, so re-submitting the
  /// same text maps to the same schedule.
  @override
  Future<ScheduleModel> fetchScheduleFromText(String text) async {
    try {
      final String syntheticLink = 'text://${await text.hashUrl}';
      final prompt = [
        Content.text(
            '''Extract the required wedding data from the given text and return it in pure JSON format, without any additional text or snippet tags.
          The text is usually an SMS or messenger invitation written in Korean.
          $_extractionGuidelines
          Put an empty string for thumbnail; pasted text has no thumbnail URL.

          Given text:
          $text
          ''')
      ];
      return await _generate(prompt, syntheticLink);
    } on FormatException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (e) {
      throw Exception('[-] Failed to fetch data from server: $e');
    }
  }

  /// Runs the model and adapts the response into a [ScheduleModel] keyed
  /// by [link], falling back to the default thumbnail.
  Future<ScheduleModel> _generate(List<Content> prompt, String link) async {
    final response = await _buildModel().generateContent(prompt);
    if (response.text != null) {
      ScheduleModel model =
          ScheduleModel.fromJson(_toModelJson(response.text!, link));
      // The prompt asks for empty strings on missing fields; a schedule
      // without a parseable datetime cannot be saved, so fail as a
      // FormatException the presentation layer can tell apart from
      // server errors.
      if (DateTime.tryParse(model.date) == null) {
        throw const FormatException(
            '[-] No parseable datetime found in the invitation');
      }
      if (model.thumbnail.isEmpty) {
        model = model.copyWith(thumbnail: Constants.defaultThumbnail);
      }
      return model;
    } else {
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
