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
import '../../../domain/entities/schedule_draft.dart';
import '../../mapper/schedule_mapper.dart';
import '../../models/schedule/schedule_model.dart';
import 'invitation_prompt.dart';
import 'schedule_remote_source.dart';

@LazySingleton(as: ScheduleRemoteSource, env: ['firebase'])
class FirebaseAiLogicImpl implements ScheduleRemoteSource {
  FirebaseAiLogicImpl();

  GenerativeModel _buildModel() {
    return FirebaseAI.googleAI().generativeModel(
      model: Constants.geminiModel,
      generationConfig: GenerationConfig(
          responseJsonSchema: scheduleResponseJsonSchema,
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
      final prompt = [Content.text(linkExtractionPrompt(parsed))];
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
      final String syntheticLink = 'image://${await bytes.hashBytes}';
      final prompt = [
        Content.multi([
          const TextPart(imageExtractionPrompt),
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
      final prompt = [Content.text(textExtractionPrompt(text))];
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
      if (model.thumbnail.isEmpty) {
        model = model.copyWith(thumbnail: Constants.defaultThumbnail);
      }
      // A schedule without a usable datetime cannot be saved as-is, so hand
      // the partial extraction to the presentation layer for manual
      // completion. Dates before 2000 count as missing: models fall back to
      // epoch-like values when an invitation has no date. Compared in local
      // time — parse converts offset strings to UTC, which would misread
      // e.g. 2000-01-01T00:30+09:00 as 1999.
      final DateTime? parsedDate = DateTime.tryParse(model.date);
      if (parsedDate == null || parsedDate.toLocal().year < 2000) {
        final ScheduleDraft draft = ScheduleMapper.toDraft(model);
        final bool hasContent = draft.groom.isNotEmpty ||
            draft.bride.isNotEmpty ||
            draft.location.isNotEmpty ||
            draft.groomAccounts.isNotEmpty ||
            draft.brideAccounts.isNotEmpty;
        // An all-empty draft would prefill nothing; fail plainly instead
        // of promising the user "what was read".
        if (!hasContent) {
          throw const FormatException(
              '[-] Nothing usable found in the invitation');
        }
        throw IncompleteScheduleException(draft);
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
      // The schema allows null for an unknown datetime; the model column
      // is a non-null string.
      'datetime': json['datetime'] ?? '',
      'groom_accounts': jsonEncode(json['groomAccounts'] ?? []),
      'bride_accounts': jsonEncode(json['brideAccounts'] ?? []),
    };
  }
}
