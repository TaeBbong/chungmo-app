/// Step 5:
/// Data source
///
/// CRUD based data source implement with remote/local source

import 'dart:async';
import 'dart:convert';

import 'package:chungmo/core/utils/crawler.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../core/utils/constants.dart';
import '../../../core/utils/image_preprocessor.dart';
import '../../../core/utils/string_extension.dart';
import '../../../domain/entities/invitation_image.dart';
import '../../../domain/entities/schedule_draft.dart';
import '../../mapper/schedule_mapper.dart';
import '../../models/schedule/schedule_model.dart';
import 'invitation_prompt.dart';
import 'schedule_remote_source.dart';

/// Sends [prompt] to the model under [schema] and returns its text.
///
/// The seam this class is tested through. `GenerativeModel` and `Content`
/// are `final` in firebase_ai, so neither can be mocked; handing back a
/// plain string instead lets a test drive every branch below without
/// constructing an SDK object at all.
typedef GenerateJson = Future<String?> Function(
    List<Content> prompt, Map<String, Object> schema);

/// Crawls an invitation link. Defaults to [crawlInvitation].
typedef CrawlPage = Future<CrawledInvitation?> Function(String url);

/// Downloads a page's images. Defaults to [fetchInvitationImages].
typedef FetchImages = Future<List<FetchedImage>> Function(List<Uri> urls);

@LazySingleton(as: ScheduleRemoteSource, env: ['firebase'])
class FirebaseAiLogicImpl implements ScheduleRemoteSource {
  final GenerateJson _generateJson;
  final CrawlPage _crawl;
  final FetchImages _fetchImages;

  /// The shipping constructor; injectable builds this one.
  FirebaseAiLogicImpl()
      : _generateJson = _callFirebaseAi,
        _crawl = crawlInvitation,
        _fetchImages = fetchInvitationImages;

  /// Replaces the three calls that leave the process — the model and the
  /// two network fetches — leaving the decisions between them intact.
  @visibleForTesting
  FirebaseAiLogicImpl.withSeams({
    required GenerateJson generateJson,
    CrawlPage? crawl,
    FetchImages? fetchImages,
  })  : _generateJson = generateJson,
        _crawl = crawl ?? crawlInvitation,
        _fetchImages = fetchImages ?? fetchInvitationImages;

  static Future<String?> _callFirebaseAi(
      List<Content> prompt, Map<String, Object> schema) async {
    final response = await FirebaseAI.googleAI()
        .generativeModel(
          model: Constants.geminiModel,
          generationConfig: GenerationConfig(
              responseJsonSchema: schema, responseMimeType: "application/json"),
        )
        .generateContent(prompt);
    return response.text;
  }

  @override
  Future<Map<String, String>> extractVenues(List<String> locations) async {
    if (locations.isEmpty) return const {};
    final String? text = await _generateJson(
        [Content.text(venueBackfillPrompt(locations))],
        venueBackfillJsonSchema);
    // A missing body is a failed extraction, not "no venues found": it must
    // propagate so the backfill's done-flag stays unset and a later launch
    // retries.
    if (text == null) {
      throw const FormatException('[-] Venue extraction returned no content');
    }
    final decoded = jsonDecode(text) as Map<String, dynamic>;
    final venues = <String, String>{};
    for (final entry in (decoded['venues'] as List? ?? const [])) {
      if (entry is! Map) continue;
      final location = entry['location']?.toString().trim() ?? '';
      final venue = entry['venue']?.toString().trim() ?? '';
      if (location.isNotEmpty && venue.isNotEmpty) venues[location] = venue;
    }
    return venues;
  }

  /// Fetch analyzed data in `json` type from Firebase AI Logic.
  ///
  /// If result, returns `ScheduleModel` type data.
  ///
  /// If not, throw error.
  @override
  Future<ScheduleModel> fetchScheduleFromServer(String link) async {
    try {
      final crawled = await _crawl(link);
      final prompt = await _linkPrompt(crawled);
      return await _generate(prompt, link);
    } on FormatException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (e) {
      throw Exception('[-] Failed to fetch data from server: $e');
    }
  }

  /// Builds the link prompt, switching to multimodal input when the crawl
  /// came back text-poor.
  ///
  /// Image-only invitations and client-rendered shells publish the wedding
  /// as pictures, so no crawler or prompt change can reach the fields; the
  /// page's own images go to the multimodal parser instead. Downloading
  /// them can fail or find nothing usable, in which case the text-only
  /// prompt still runs — the fallback may not turn a parseable page into a
  /// failed one.
  Future<List<Content>> _linkPrompt(CrawledInvitation? crawled) async {
    final String text = crawled?.text ?? '';
    if (crawled == null || !needsImageFallback(crawled)) {
      return [Content.text(linkExtractionPrompt(text))];
    }
    final List<FetchedImage> images = await _fetchImages(crawled.images);
    if (images.isEmpty) return [Content.text(linkExtractionPrompt(text))];
    final parts = <Part>[
      TextPart(linkExtractionPrompt(text, withImages: true))
    ];
    for (final image in images) {
      try {
        // Same downscaling contract as the picked-image path: a vendor's
        // full-resolution section image is often several MB.
        final prepared = await ImagePreprocessor.downscale(
            InvitationImage(bytes: image.bytes, mimeType: image.mimeType));
        parts.add(InlineDataPart(prepared.mimeType, prepared.bytes));
      } on Exception {
        // One picture we cannot prepare — over the decode pixel limit, or a
        // frame that will not decode — drops out of the prompt. Letting it
        // escape would turn a page the text-only prompt could have parsed
        // into a hard failure, since the caller rethrows FormatException.
      }
    }
    if (parts.length == 1) return [Content.text(linkExtractionPrompt(text))];
    return [Content.multi(parts)];
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
          TextPart(imageExtractionPrompt()),
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
    final String? text =
        await _generateJson(prompt, scheduleResponseJsonSchema);
    if (text != null) {
      ScheduleModel model = ScheduleModel.fromJson(_toModelJson(text, link));
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
