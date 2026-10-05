/// Tests for the parsing pipeline's decisions.
///
/// The model call and the two network fetches are replaced through
/// `FirebaseAiLogicImpl.withSeams`; everything between them is the real
/// code. `GenerativeModel` and `Content` are `final` in firebase_ai, so the
/// SDK cannot be mocked — the seam hands back a plain string instead.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:chungmo/core/utils/constants.dart';
import 'package:chungmo/core/utils/crawler.dart';
import 'package:chungmo/data/sources/remote/firebase_ai_logic_impl.dart';
import 'package:chungmo/domain/entities/schedule_draft.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';

/// A complete model answer; individual tests override what they are about.
String _response({
  String groom = '김민준',
  String bride = '이서연',
  String? datetime = '2026-10-17T13:30:00+09:00',
  String location = '라온컨벤션 3층 그랜드홀',
  String venue = '라온컨벤션',
  String thumbnail = 'https://vendor.test/main.jpg',
  List<Map<String, String>> groomAccounts = const [],
  List<Map<String, String>> brideAccounts = const [],
}) =>
    jsonEncode({
      'groom': groom,
      'bride': bride,
      'datetime': datetime,
      'location': location,
      'venue': venue,
      'thumbnail': thumbnail,
      'groomAccounts': groomAccounts,
      'brideAccounts': brideAccounts,
    });

/// Captures what the pipeline asked the model, and answers with [reply].
class _Model {
  final String? reply;
  final List<List<Content>> prompts = [];
  final List<Map<String, Object>> schemas = [];

  _Model(this.reply);

  Future<String?> call(List<Content> prompt, Map<String, Object> schema) async {
    prompts.add(prompt);
    schemas.add(schema);
    return reply;
  }

  List<Part> get parts => prompts.single.single.parts;
  String get text => parts.whereType<TextPart>().single.text;
  List<InlineDataPart> get images => parts.whereType<InlineDataPart>().toList();
}

/// Bytes no decoder recognises: `ImagePreprocessor` passes them through
/// untouched, which keeps these tests off real image work.
Uint8List _opaque([int size = 32]) =>
    Uint8List.fromList(List<int>.filled(size, 0x7F));

FetchedImage _image(String name, {int size = 32}) => FetchedImage(
    _opaque(size), 'image/png', Uri.parse('https://vendor.test/$name'));

/// A crawl with almost no Korean, which is what sends the parser to the
/// images — the same rule `needsImageFallback` applies.
CrawledInvitation _textPoor({int images = 3}) => CrawledInvitation(
      '김민준♥이서연 청첩장\n${List.generate(images, (i) => '[IMAGE] https://vendor.test/$i.png').join('\n')}',
      List.generate(images, (i) => Uri.parse('https://vendor.test/$i.png')),
    );

CrawledInvitation _textRich() =>
    CrawledInvitation('결혼식에 초대합니다 ' * 20, [Uri.parse('https://x.test/a.png')]);

void main() {
  group('fetchScheduleFromText', () {
    test('adapts the answer into a schedule keyed by the input', () async {
      final model = _Model(_response());
      final source = FirebaseAiLogicImpl.withSeams(generateJson: model.call);

      final schedule = await source.fetchScheduleFromText('청첩장 문자');

      expect(schedule.groom, '김민준');
      expect(schedule.venue, '라온컨벤션');
      // Content-addressed, so re-submitting the same text is the same row.
      expect(schedule.link, startsWith('text://'));
    });

    test('re-encodes the account arrays into their text columns', () async {
      final model = _Model(_response(groomAccounts: [
        {'bank': '국민은행', 'number': '123456-78-901234', 'holder': '김민준'}
      ]));
      final source = FirebaseAiLogicImpl.withSeams(generateJson: model.call);

      final schedule = await source.fetchScheduleFromText('문자');

      // The DB keeps one TEXT column per side, so the list arrives encoded.
      expect(jsonDecode(schedule.groomAccounts), hasLength(1));
      expect(schedule.brideAccounts, '[]');
    });

    test('falls back to the default thumbnail when the answer has none',
        () async {
      final model = _Model(_response(thumbnail: ''));
      final source = FirebaseAiLogicImpl.withSeams(generateJson: model.call);

      expect((await source.fetchScheduleFromText('문자')).thumbnail,
          Constants.defaultThumbnail);
    });

    test('throws when the model answers with nothing', () async {
      final source =
          FirebaseAiLogicImpl.withSeams(generateJson: _Model(null).call);

      expect(source.fetchScheduleFromText('문자'), throwsA(isA<Exception>()));
    });
  });

  group('a schedule with no usable date', () {
    Future<Object?> capture(Future<void> Function() body) async {
      try {
        await body();
      } catch (error) {
        return error;
      }
      return null;
    }

    test('hands back what was read, for the manual form to prefill', () async {
      final model = _Model(_response(datetime: null));
      final source = FirebaseAiLogicImpl.withSeams(generateJson: model.call);

      final error =
          await capture(() => source.fetchScheduleFromText('날짜 없는 문자'));

      expect(error, isA<IncompleteScheduleException>());
      final ScheduleDraft draft = (error as IncompleteScheduleException).draft;
      expect(draft.groom, '김민준');
      expect(draft.location, '라온컨벤션 3층 그랜드홀');
    });

    test('treats a pre-2000 date as no date at all', () async {
      // Models fall back to epoch-like values when an invitation states no
      // date, and 1970 must not reach the calendar as a real wedding.
      final model = _Model(_response(datetime: '1970-01-01T00:00:00+09:00'));
      final source = FirebaseAiLogicImpl.withSeams(generateJson: model.call);

      expect(await capture(() => source.fetchScheduleFromText('문자')),
          isA<IncompleteScheduleException>());
    });

    test('keeps a date from this century', () async {
      final model = _Model(_response(datetime: '2000-06-15T12:00:00+09:00'));
      final source = FirebaseAiLogicImpl.withSeams(generateJson: model.call);

      expect((await source.fetchScheduleFromText('문자')).groom, '김민준');
    });

    // Not pinned here: the production code compares in local time, so an
    // instant within hours of the 2000 boundary falls on either side of it
    // depending on the machine's zone, and Dart offers no way to set that
    // for a test. A wedding on 2000-01-01 is not a case this app meets.

    test('fails plainly when nothing at all was read', () async {
      // An empty draft would prefill an empty form and promise the user
      // something was understood.
      final model = _Model(_response(
          datetime: null, groom: '', bride: '', location: '', venue: ''));
      final source = FirebaseAiLogicImpl.withSeams(generateJson: model.call);

      final error = await capture(() => source.fetchScheduleFromText('문자'));

      expect(error, isA<FormatException>());
      expect(error, isNot(isA<IncompleteScheduleException>()));
    });
  });

  group('fetchScheduleFromServer', () {
    test('sends the crawled text alone when the page carries Korean', () async {
      final model = _Model(_response());
      final source = FirebaseAiLogicImpl.withSeams(
        generateJson: model.call,
        crawl: (_) async => _textRich(),
        fetchImages: (_) async => fail('must not download on a text page'),
      );

      await source.fetchScheduleFromServer('https://vendor.test/card');

      expect(model.images, isEmpty);
      expect(model.text, contains('결혼식에 초대합니다'));
      expect(model.text, isNot(contains('its own images are attached')));
    });

    test('attaches the page images when the crawl is text-poor', () async {
      final model = _Model(_response());
      final source = FirebaseAiLogicImpl.withSeams(
        generateJson: model.call,
        crawl: (_) async => _textPoor(),
        fetchImages: (_) async => [_image('a.png'), _image('b.png')],
      );

      await source.fetchScheduleFromServer('https://vendor.test/card');

      expect(model.images, hasLength(2));
      // The model is told which of the two to trust.
      expect(model.text, contains('its own images are attached'));
    });

    test('keeps the link as the key, so the same URL is the same schedule',
        () async {
      final model = _Model(_response());
      final source = FirebaseAiLogicImpl.withSeams(
        generateJson: model.call,
        crawl: (_) async => _textPoor(),
        fetchImages: (_) async => [_image('a.png')],
      );

      final schedule =
          await source.fetchScheduleFromServer('https://vendor.test/card');

      expect(schedule.link, 'https://vendor.test/card');
    });

    test('falls back to text when none of the images download', () async {
      // The documented contract: the fallback may not turn a page the
      // text-only prompt could have parsed into a failure.
      final model = _Model(_response());
      final source = FirebaseAiLogicImpl.withSeams(
        generateJson: model.call,
        crawl: (_) async => _textPoor(),
        fetchImages: (_) async => const [],
      );

      await source.fetchScheduleFromServer('https://vendor.test/card');

      expect(model.images, isEmpty);
      expect(model.text, isNot(contains('its own images are attached')));
    });

    test('still parses when the crawl comes back empty-handed', () async {
      final model = _Model(_response());
      final source = FirebaseAiLogicImpl.withSeams(
        generateJson: model.call,
        crawl: (_) async => null,
        fetchImages: (_) async => fail('nothing to download'),
      );

      await source.fetchScheduleFromServer('https://vendor.test/card');

      expect(model.prompts, hasLength(1));
    });
  });

  group('extractVenues', () {
    test('answers without calling the model for an empty batch', () async {
      final model = _Model(null);
      final source = FirebaseAiLogicImpl.withSeams(generateJson: model.call);

      expect(await source.extractVenues(const []), isEmpty);
      expect(model.prompts, isEmpty);
    });

    test('maps each location to its venue and asks under the venue schema',
        () async {
      final model = _Model(jsonEncode({
        'venues': [
          {'location': '라온컨벤션 3층 그랜드홀', 'venue': '라온컨벤션'},
          {'location': '그랜드컨벤션 2층', 'venue': '그랜드컨벤션'},
        ]
      }));
      final source = FirebaseAiLogicImpl.withSeams(generateJson: model.call);

      final venues = await source.extractVenues(['라온컨벤션 3층 그랜드홀', '그랜드컨벤션 2층']);

      expect(venues['라온컨벤션 3층 그랜드홀'], '라온컨벤션');
      expect(model.schemas.single, isNot(contains('groomAccounts')));
    });

    test('drops entries the model left blank', () async {
      final model = _Model(jsonEncode({
        'venues': [
          {'location': '주소만 있는 문자열', 'venue': ''},
          {'location': '', 'venue': '이름만'},
          {'location': '라온컨벤션 3층', 'venue': '라온컨벤션'},
        ]
      }));
      final source = FirebaseAiLogicImpl.withSeams(generateJson: model.call);

      expect(await source.extractVenues(const ['x']), {'라온컨벤션 3층': '라온컨벤션'});
    });

    test('throws on a missing body so the backfill retries next launch',
        () async {
      // Returning {} would set the done-flag and strand every schedule.
      final source =
          FirebaseAiLogicImpl.withSeams(generateJson: _Model(null).call);

      expect(
          source.extractVenues(const ['x']), throwsA(isA<FormatException>()));
    });
  });
}
