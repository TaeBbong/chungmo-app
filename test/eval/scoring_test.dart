import 'package:flutter_test/flutter_test.dart';

import '../../eval/scoring.dart';

void main() {
  final pageUrl = Uri.parse('https://chung-mo.web.app/eval/hanul-01/');
  final expected = <String, dynamic>{
    'groom': '김민준',
    'bride': '이서연',
    'datetime': '2026-10-17T13:30:00+09:00',
    'locationKeywords': ['라온컨벤션'],
    'groomAccounts': [
      {
        'bank': '국민은행',
        'number': '123456-78-901234',
        'holder': '김민준',
        'relation': '신랑'
      },
    ],
    'brideAccounts': [
      {
        'bank': '카카오뱅크',
        'number': '3333-01-1234567',
        'holder': '이서연',
        'relation': '신부'
      },
    ],
    'thumbnails': ['https://chung-mo.web.app/eval/hanul-01/main.svg'],
  };

  group('scoreCase', () {
    test('marks every field correct for an exact prediction', () {
      final score = scoreCase(
          expected,
          {
            'groom': '김민준',
            'bride': '이서연',
            'datetime': '2026-10-17T13:30:00+09:00',
            'location': '라온컨벤션 3층 그랜드홀',
            'groomAccounts': [
              {
                'bank': '국민',
                'number': '123456-78-901234',
                'holder': '김민준',
                'relation': '신랑'
              }
            ],
            'brideAccounts': [
              {
                'bank': '카카오뱅크',
                'number': '3333011234567',
                'holder': '이서연',
                'relation': '신부'
              }
            ],
            'thumbnail': './main.svg',
          },
          pageUrl: pageUrl);
      expect(score.core, isTrue);
      expect(score.thumbnail, isTrue,
          reason: 'relative thumbnails resolve against the page URL');
      expect(score.mismatches, isEmpty);
    });

    test('a failed call scores as all wrong but keeps lenient flags false', () {
      final score = scoreCase(expected, null, pageUrl: pageUrl);
      expect(score.core, isFalse);
      expect(score.groomLenient, isFalse);
      expect(score.accountRecall, 0.0);
      expect(
          score.mismatches.keys,
          containsAll([
            'groom',
            'bride',
            'datetime',
            'location',
            'accounts',
            'thumbnail'
          ]));
    });

    test('given name only is lenient, not exact', () {
      final score = scoreCase(expected, {'groom': '민준', 'bride': '신부 이서연'},
          pageUrl: pageUrl);
      expect(score.groom, isFalse);
      expect(score.groomLenient, isTrue);
      expect(score.bride, isTrue, reason: 'role prefixes are stripped');
    });

    test('aliases accept the romanised form of a name', () {
      final withAliases = {
        ...expected,
        'groomAliases': ['Minjun Kim'],
        'brideAliases': ['Seoyeon Lee'],
      };
      final score = scoreCase(
          withAliases, {'groom': 'Minjun Kim', 'bride': 'seoyeon lee'},
          pageUrl: pageUrl);
      expect(score.groom, isTrue);
      expect(score.bride, isTrue);
      expect(scoreCase(withAliases, {'groom': 'Kim'}, pageUrl: pageUrl).groom,
          isFalse);
    });

    test('accounts compare as a set of side|bank|number keys', () {
      final score = scoreCase(
          expected,
          {
            'groomAccounts': [
              {'bank': 'KB국민은행', 'number': '123456 78 901234', 'holder': '김민준'},
              {'bank': '신한', 'number': '110-1-1', 'holder': '김영수'},
            ],
            'brideAccounts': const [],
          },
          pageUrl: pageUrl);
      expect(score.accounts, isFalse);
      expect(score.accountPrecision, closeTo(0.5, 1e-9));
      expect(score.accountRecall, closeTo(0.5, 1e-9));
      expect(
          score.mismatches['accounts'], contains('bride|카카오뱅크|3333011234567'));
    });

    test('an account on the wrong side does not match', () {
      final score = scoreCase(
          expected,
          {
            'groomAccounts': [
              {'bank': '카카오뱅크', 'number': '3333-01-1234567', 'holder': '이서연'},
            ],
            'brideAccounts': [
              {'bank': '국민은행', 'number': '123456-78-901234', 'holder': '김민준'},
            ],
          },
          pageUrl: pageUrl);
      expect(score.accounts, isFalse);
      expect(score.accountRecall, 0.0);
    });

    test('empty expected accounts require an empty prediction', () {
      final noAccounts = {
        ...expected,
        'groomAccounts': const [],
        'brideAccounts': const []
      };
      expect(
          scoreCase(noAccounts,
                  {'groomAccounts': const [], 'brideAccounts': const []},
                  pageUrl: pageUrl)
              .accounts,
          isTrue);
      expect(scoreCase(noAccounts, {}, pageUrl: pageUrl).accounts, isTrue);
      expect(
          scoreCase(
                  noAccounts,
                  {
                    'groomAccounts': [
                      {'bank': '국민', 'number': '1-2-3'}
                    ]
                  },
                  pageUrl: pageUrl)
              .accounts,
          isFalse);
    });
  });

  group('datetimeMatches', () {
    test('accepts the same instant in another offset', () {
      expect(
          datetimeMatches('2026-10-17T13:30:00+09:00', '2026-10-17T04:30:00Z'),
          isTrue);
    });

    test('reads an offset-less prediction as KST', () {
      expect(
          datetimeMatches('2026-10-17T13:30:00+09:00', '2026-10-17T13:30:00'),
          isTrue);
      expect(datetimeMatches('2026-10-17T13:30:00+09:00', '2026-10-17 13:30'),
          isTrue);
    });

    test('rejects a different minute, day or year', () {
      expect(
          datetimeMatches(
              '2026-10-17T13:30:00+09:00', '2026-10-17T13:00:00+09:00'),
          isFalse);
      expect(
          datetimeMatches(
              '2026-10-17T13:30:00+09:00', '2025-10-17T13:30:00+09:00'),
          isFalse);
    });

    test('a null expectation is met only by an empty or null prediction', () {
      expect(datetimeMatches(null, ''), isTrue);
      expect(datetimeMatches(null, 'null'), isTrue);
      expect(datetimeMatches(null, '2027-03-01T12:00:00+09:00'), isFalse);
    });
  });

  group('crawlCoverage', () {
    test('finds expected values ignoring whitespace and hyphens', () {
      final cov = crawlCoverage({
        ...expected,
        'dateText': '2026년 10월 17일 토요일 오후 1시 30분',
      }, '''
[IMAGE] ./main.svg
김민준 ♥ 이서연
2026년 10월 17일 토요일
오후 1시 30분
라온컨벤션 3층
국민은행 123456 78 901234 / 카카오뱅크 3333011234567
''');
      expect(cov, {
        'groom': true,
        'bride': true,
        'date': true,
        'location': true,
        'accounts': true,
      });
    });

    test('an empty crawl covers nothing except a missing date', () {
      final cov = crawlCoverage({...expected, 'dateText': ''}, null);
      expect(cov['groom'], isFalse);
      expect(cov['accounts'], isFalse);
      expect(cov['date'], isTrue,
          reason: 'no-date invitations have nothing to find');
    });
  });

  group('normalizers', () {
    test('bank aliases fold to one token', () {
      expect(normalizeBank('KB국민은행'), '국민');
      expect(normalizeBank('국민'), '국민');
      expect(normalizeBank('NH농협은행'), '농협');
      expect(normalizeBank('카카오 뱅크'), '카카오뱅크');
      expect(normalizeBank('토스'), '토스뱅크');
    });

    test('account numbers keep digits only', () {
      expect(normalizeAccountNumber('110-123-456789'), '110123456789');
      expect(normalizeAccountNumber('110 123 456789'), '110123456789');
    });

    test('location needs every keyword ignoring spaces', () {
      expect(locationMatches(['호텔 라비앙'], '호텔라비앙 2층 크리스탈볼룸'), isTrue);
      expect(locationMatches(['호텔 라비앙'], '크리스탈볼룸'), isFalse);
      expect(locationMatches(['호텔 라비앙'], ''), isFalse);
    });
  });
}
