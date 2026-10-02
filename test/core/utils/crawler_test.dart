import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chungmo/core/utils/crawler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final base = Uri.parse('https://vendor.example/card/abc/');

  String extract(String html) => extractContentFromHtml(html, base).text;

  _imageFallbackTests();

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

    test('resolves relative URLs against <base href> when present', () {
      final result = extractContentFromHtml('''
<html><head><base href="https://cdn.vendor.example/cards/xyz/">
<meta property="og:image" content="cover.jpg"></head>
<body><img src="photos/1.jpg"><iframe src="frame.html"></iframe></body></html>''',
          base);
      expect(
          result.text,
          contains(
              '[META] og:image → https://cdn.vendor.example/cards/xyz/cover.jpg'));
      expect(
          result.text,
          contains(
              '[IMAGE] https://cdn.vendor.example/cards/xyz/photos/1.jpg'));
      expect(result.iframes.single.toString(),
          'https://cdn.vendor.example/cards/xyz/frame.html');
    });

    test('keeps text hidden by inline styles (modals, toggled accounts)', () {
      final text = extract(
          '<div style="display:none"><p>신한 110-123-456789 예금주 이서연</p></div>');
      expect(text, contains('신한 110-123-456789 예금주 이서연'));
    });
  });

  group('fetchPage', () {
    test('follows redirects by hand and reports the final URL', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/s/abc') {
          return http.Response('', 301, headers: {'location': '/card/real/'});
        }
        return http.Response('<p>안녕</p>', 200,
            headers: {'content-type': 'text/html; charset=utf-8'});
      });
      final page =
          await fetchPage('https://vendor.example/s/abc', client: client);
      expect(page!.finalUri.toString(), 'https://vendor.example/card/real/');
      expect(page.html, '<p>안녕</p>');
    });

    test('gives up on a body stream that never closes', () async {
      final controller = StreamController<List<int>>();
      controller.add(utf8.encode('<p>partial'));
      final client = MockClient.streaming((request, body) async =>
          http.StreamedResponse(controller.stream, 200,
              headers: {'content-type': 'text/html; charset=utf-8'}));
      final page = await fetchPage('https://vendor.example/hang',
          client: client, timeout: const Duration(milliseconds: 200));
      expect(page, isNull);
      await controller.close();
    });

    test('returns null for non-200 responses and network errors', () async {
      final notFound = MockClient((_) async => http.Response('nope', 404));
      expect(await fetchPage('https://vendor.example/x', client: notFound),
          isNull);
      final failing =
          MockClient((_) async => throw const SocketException('down'));
      expect(
          await fetchPage('https://vendor.example/x', client: failing), isNull);
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

  group('CSR shell fallback', () {
    const shell = '''
<html><head><title>고진우 ♥ 심하윤</title>
<script type="module" src="./app.js"></script></head>
<body><div id="root"></div></body></html>''';
    const bundle = '''
const root = document.getElementById('root');
fetch('./data.json').then(r => r.json()).then(render);''';
    const data =
        '{"accounts":{"groom":[{"bank":"부산은행","number":"271068-41-392679"}]}}';

    test('follows a same-origin JSON referenced by the shell bundle',
        () async {
      final requested = <String>[];
      final client = MockClient((request) async {
        requested.add(request.url.path);
        switch (request.url.path) {
          case '/card/':
            return http.Response(shell, 200,
                headers: {'content-type': 'text/html; charset=utf-8'});
          case '/card/app.js':
            return http.Response(bundle, 200);
          case '/card/data.json':
            return http.Response(data, 200,
                headers: {'content-type': 'application/json'});
        }
        return http.Response('nope', 404);
      });
      final text = (await crawlInvitation('https://vendor.example/card/',
              client: client))!
          .text;
      expect(text, contains('[DATA] https://vendor.example/card/data.json'));
      expect(text, contains('부산은행'));
      expect(requested, contains('/card/app.js'));
    });

    test('leaves pages with real text content alone', () async {
      final filler = List.generate(
          60, (i) => '<p>결혼식에 초대합니다 좋은 날 함께해 주세요 $i번째 안내</p>').join();
      final requested = <String>[];
      final client = MockClient((request) async {
        requested.add(request.url.path);
        return http.Response(
            '<html><head><script src="./app.js"></script></head>'
            '<body>$filler</body></html>',
            200,
            headers: {'content-type': 'text/html; charset=utf-8'});
      });
      await crawlInvitation('https://vendor.example/card/', client: client);
      expect(requested, isNot(contains('/card/app.js')));
    });

    test('rejects same-host resources on another port or scheme', () async {
      final requested = <String>[];
      final client = MockClient((request) async {
        requested.add(request.url.toString());
        return http.Response(
            '<html><head><title>x</title>'
            '<script src="https://vendor.example:8443/app.js"></script>'
            '<script src="http://vendor.example/plain.js"></script></head>'
            '<body><div id="root"></div></body></html>',
            200,
            headers: {'content-type': 'text/html; charset=utf-8'});
      });
      await crawlInvitation('https://vendor.example/card/', client: client);
      expect(requested,
          isNot(contains('https://vendor.example:8443/app.js')));
      expect(requested, isNot(contains('http://vendor.example/plain.js')));
    });

    test('abandons a resource that redirects off the origin', () async {
      final requested = <String>[];
      final client = MockClient((request) async {
        requested.add(request.url.toString());
        switch (request.url.path) {
          case '/card/':
            return http.Response(shell, 200,
                headers: {'content-type': 'text/html; charset=utf-8'});
          case '/card/app.js':
            return http.Response(bundle, 200);
          case '/card/data.json':
            return http.Response('', 302,
                headers: {'location': 'http://169.254.169.254/meta.json'});
        }
        return http.Response('secret', 200);
      });
      final text = (await crawlInvitation('https://vendor.example/card/',
              client: client))!
          .text;
      expect(requested, isNot(contains('http://169.254.169.254/meta.json')));
      expect(text, isNot(contains('secret')));
    });

    test('never leaves the page origin', () async {
      final requested = <String>[];
      final client = MockClient((request) async {
        requested.add(request.url.toString());
        if (request.url.path == '/card/') {
          return http.Response(
              '<html><head><title>x</title>'
              '<script src="https://cdn.other.example/app.js"></script>'
              '<script src="./local.js"></script></head>'
              '<body><div id="root"></div></body></html>',
              200,
              headers: {'content-type': 'text/html; charset=utf-8'});
        }
        if (request.url.path == '/card/local.js') {
          return http.Response(
              "fetch('https://api.other.example/data.json')", 200);
        }
        return http.Response('nope', 404);
      });
      await crawlInvitation('https://vendor.example/card/', client: client);
      expect(requested, isNot(contains('https://cdn.other.example/app.js')));
      expect(
          requested, isNot(contains('https://api.other.example/data.json')));
    });
  });
}

/// A minimal PNG: the 8-byte signature padded past the content-size floor,
/// so the type sniffer and the size filter both see a real image.
List<int> _png([int size = 20 << 10]) =>
    [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, ...List.filled(size, 0)];

void _imageFallbackTests() {
  group('image collection', () {
    final base = Uri.parse('https://vendor.example/card/');

    test('collects og:image first, then images in document order', () {
      final content = extractContentFromHtml('''
<html><head><meta property="og:image" content="./share.jpg"></head>
<body><img src="./a.jpg"><img data-src="./b.jpg"><img src="data:image/gif;base64,R0lGOD"></body></html>
''', base);
      expect(
          content.images.map((u) => u.toString()),
          [
            'https://vendor.example/card/share.jpg',
            'https://vendor.example/card/a.jpg',
            'https://vendor.example/card/b.jpg',
          ]);
    });

    test('keeps one entry when og:image repeats a document image', () {
      final content = extractContentFromHtml('''
<html><head><meta property="og:image" content="https://vendor.example/card/a.jpg"></head>
<body><img src="./a.jpg"></body></html>
''', base);
      expect(content.images, hasLength(1));
    });
  });

  group('needsImageFallback', () {
    CrawledInvitation crawled(String text, {int images = 1}) =>
        CrawledInvitation(
            text,
            List.generate(
                images, (i) => Uri.parse('https://vendor.example/$i.jpg')));

    test('fires on a page that is pictures with almost no Korean', () {
      // The shape of the image-only fixtures: a title and a wall of URLs.
      final text = StringBuffer('김민준♥이서연 청첩장\n');
      for (var i = 0; i < 7; i++) {
        text.writeln('[IMAGE] https://vendor.example/card/section-$i.png');
      }
      expect(hangulLength(text.toString()), lessThan(45));
      expect(needsImageFallback(crawled(text.toString(), images: 7)), isTrue);
    });

    test('leaves a page carrying real Korean text alone', () {
      final text = '결혼식에 초대합니다 ' * 10;
      expect(needsImageFallback(crawled(text, images: 7)), isFalse);
    });

    test('does not fire when the page has no images to send', () {
      expect(needsImageFallback(crawled('김민준', images: 0)), isFalse);
    });
  });

  group('fetchInvitationImages', () {
    Uri u(String p) => Uri.parse('https://vendor.example/$p');

    test('keeps content images and skips icons, SVG and failures', () async {
      final client = MockClient((request) async {
        switch (request.url.path) {
          case '/icon.png':
            // A real PNG, but sprite-sized: below the content floor.
            return http.Response.bytes(_png(200), 200);
          case '/logo.svg':
            return http.Response.bytes(List.filled(20 << 10, 0x3C), 200,
                headers: {'content-type': 'image/svg+xml'});
          case '/gone.jpg':
            return http.Response('', 404);
          case '/main.png':
            return http.Response.bytes(_png(), 200);
        }
        return http.Response('', 404);
      });
      final images = await fetchInvitationImages(
          [u('icon.png'), u('logo.svg'), u('gone.jpg'), u('main.png')],
          client: client);
      expect(images.map((i) => i.uri.path), ['/main.png']);
      expect(images.single.mimeType, 'image/png');
    });

    test('sniffs the type when the server mislabels it', () async {
      final client = MockClient((request) async => http.Response.bytes(
          _png(), 200,
          headers: {'content-type': 'application/octet-stream'}));
      final images =
          await fetchInvitationImages([u('a.bin')], client: client);
      expect(images.single.mimeType, 'image/png');
    });

    test('stops at the send limit instead of downloading every image',
        () async {
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        return http.Response.bytes(_png(), 200);
      });
      final images = await fetchInvitationImages(
          List.generate(9, (i) => u('$i.png')),
          client: client);
      expect(images, hasLength(5));
      expect(requests, 5);
    });

    test('refuses a body that hit the size cap', () async {
      // 4 MiB is the body ceiling; a bigger image arrives as a prefix, and
      // half a JPEG must not be presented to the model as the invitation.
      final oversized = _png((5 << 20));
      final client = MockClient(
          (request) async => http.Response.bytes(oversized, 200));
      final images =
          await fetchInvitationImages([u('huge.png')], client: client);
      expect(images, isEmpty);
    });

    test('stops when the overall budget runs out', () async {
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        await Future<void>.delayed(const Duration(milliseconds: 120));
        return http.Response.bytes(_png(), 200);
      });
      final images = await fetchInvitationImages(
          List.generate(8, (i) => u('$i.png')),
          client: client,
          budget: const Duration(milliseconds: 250));
      // Without a shared budget all 5 keepers would be fetched; the clock
      // cuts it short instead, and what arrived still gets used.
      expect(requests, lessThan(5));
      expect(images, isNotEmpty);
    });

    test('gives up after the attempt cap when nothing is usable', () async {
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        return http.Response('', 404);
      });
      final images = await fetchInvitationImages(
          List.generate(20, (i) => u('$i.png')),
          client: client);
      expect(images, isEmpty);
      expect(requests, 8);
    });
  });

  group('crawlInvitation', () {
    test('carries the page images alongside the text', () async {
      final client = MockClient((request) async => http.Response(
          '<html><head><title>김민준♥이서연 청첩장</title>'
          '<meta property="og:image" content="./share.jpg"></head>'
          '<body><img src="./main.png"></body></html>',
          200,
          headers: {'content-type': 'text/html; charset=utf-8'}));
      final crawled =
          await crawlInvitation('https://vendor.example/card/', client: client);
      expect(crawled!.images.map((u) => u.path),
          ['/card/share.jpg', '/card/main.png']);
      expect(crawled.text, contains('[IMAGE] https://vendor.example/card/main.png'));
    });
  });
}
