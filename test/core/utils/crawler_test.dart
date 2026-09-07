import 'dart:convert';

import 'package:chungmo/core/utils/crawler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final base = Uri.parse('https://vendor.example/card/abc/');

  String extract(String html) => extractContentFromHtml(html, base).text;

  group('extractContentFromHtml', () {
    test('emits visible text in document order without nested duplicates', () {
      final text = extract('''
<html><body>
<div class="wrap"><div class="hero"><p>김민준 ♥ 이서연</p><p>2026년 10월 17일 토요일 오후 1시 30분</p></div>
<section><h2>오시는 길</h2><span>라온컨벤션</span> <span>3층 그랜드홀</span></section></div>
</body></html>''');
      expect(text.split('\n'), [
        '김민준 ♥ 이서연',
        '2026년 10월 17일 토요일 오후 1시 30분',
        '오시는 길',
        '라온컨벤션 3층 그랜드홀',
      ]);
    });

    test('reads table cells, <time> and other non-div containers', () {
      final text = extract('''
<table><tr><td>일시</td><td><time datetime="2026-10-17T13:30:00+09:00">2026.10.17 (토) 13:30</time></td></tr>
<tr><td>계좌</td><td>국민은행 123456-78-901234 김민준</td></tr></table>
<header>WEDDING INVITATION</header>''');
      expect(text, contains('2026.10.17 (토) 13:30'));
      expect(text, contains('국민은행 123456-78-901234 김민준'));
      expect(text, contains('WEDDING INVITATION'));
    });

    test('keeps English lines', () {
      final text = extract('<p>Saturday, October 17, 2026 at 1:30 PM</p>');
      expect(text, contains('Saturday, October 17, 2026 at 1:30 PM'));
    });

    test('surfaces OpenGraph meta and resolves og:image', () {
      final text = extract('''
<html><head><title>민준 ♥ 서연 결혼합니다</title>
<meta property="og:title" content="민준 ♥ 서연 결혼합니다">
<meta property="og:description" content="2026년 10월 17일 라온컨벤션">
<meta property="og:image" content="./main.jpg">
<meta name="viewport" content="width=device-width"></head><body></body></html>''');
      expect(text.split('\n'), [
        '민준 ♥ 서연 결혼합니다',
        '[META] og:title → 민준 ♥ 서연 결혼합니다',
        '[META] og:description → 2026년 10월 17일 라온컨벤션',
        '[META] og:image → https://vendor.example/card/abc/main.jpg',
      ]);
    });

    test('prefers the lazy-load source over a data: placeholder and resolves',
        () {
      final text = extract('''
<img src="data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7" data-src="../photos/main.jpg">
<img src="/static/gallery-1.jpg">''');
      expect(text.split('\n'), [
        '[IMAGE] https://vendor.example/card/photos/main.jpg',
        '[IMAGE] https://vendor.example/static/gallery-1.jpg',
      ]);
    });

    test('emits anchors with resolved hrefs and lists iframes', () {
      final result = extractContentFromHtml('''
<a href="https://map.kakao.com/link/search/라온컨벤션">카카오맵</a>
<a href="javascript:void(0)">공유하기</a>
<iframe src="./content.html"></iframe>
<iframe src="https://www.google.com/maps/embed?pb=1"></iframe>''', base);
      expect(result.text.split('\n'), [
        '[ANCHOR] 카카오맵 → https://map.kakao.com/link/search/라온컨벤션',
        '공유하기',
        '[IFRAME] https://vendor.example/card/abc/content.html',
        '[IFRAME] https://www.google.com/maps/embed?pb=1',
      ]);
      expect(result.iframes.map((u) => u.host),
          ['vendor.example', 'www.google.com']);
    });

    test('keeps data scripts and Korean scripts, drops the rest', () {
      final text = extract('''
<script type="application/ld+json">{"@type":"Event","startDate":"2026-10-17T13:30:00+09:00"}</script>
<script id="__NEXT_DATA__" type="application/json">{"props":{"groom":"김민준"}}</script>
<script>function copy(){alert('계좌번호가 복사되었습니다');}</script>
<script>var analytics = require('ga'); analytics.init('UA-1');</script>
<script src="/app.js"></script>
<style>.x{display:none}</style>''');
      expect(text, contains('[SCRIPT] {"@type":"Event"'));
      expect(text, contains('[SCRIPT] {"props":{"groom":"김민준"}}'));
      expect(text, contains('계좌번호가 복사되었습니다'));
      expect(text, isNot(contains('analytics')));
      expect(text, isNot(contains('display:none')));
    });

    test('keeps text hidden by inline styles (modals, toggled accounts)', () {
      final text = extract(
          '<div style="display:none"><p>신한 110-123-456789 예금주 이서연</p></div>');
      expect(text, contains('신한 110-123-456789 예금주 이서연'));
    });
  });

  group('decodeBody', () {
    // '<p>송태양 결혼합니다</p>' in CP949, produced by Python's codec.
    const eucBytes = [
      0x3c, 0x70, 0x3e, 188, 219, 197, 194, 190, 231, 32, 176, 225, 200, 165, //
      199, 213, 180, 207, 180, 217, 0x3c, 0x2f, 0x70, 0x3e
    ];
    const decoded = '<p>송태양 결혼합니다</p>';

    test('decodes EUC-KR declared in the Content-Type header', () {
      expect(decodeBody(eucBytes, 'text/html; charset=euc-kr'), decoded);
      expect(decodeBody(eucBytes, 'text/html; Charset=EUC-KR'), decoded);
    });

    test('sniffs the <meta charset> when the header has none', () {
      final head = latin1.encode(
          '<html><head><meta http-equiv="Content-Type" content="text/html; charset=euc-kr"></head>');
      expect(
          decodeBody([...head, ...eucBytes], 'text/html'), endsWith(decoded));
      expect(decodeBody([...head, ...eucBytes], null), endsWith(decoded));
    });

    test('defaults to lenient UTF-8', () {
      final bytes = utf8.encode('<p>김민준</p>');
      expect(decodeBody(bytes, 'text/html'), '<p>김민준</p>');
      expect(
          decodeBody([0x3c, 0x70, 0x3e, 0xff, 0xfe, 0x3c, 0x2f, 0x70, 0x3e],
              'text/html; charset=utf-8'),
          contains('<p>'));
    });
  });
}
