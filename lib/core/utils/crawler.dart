/// Turns an invitation URL into the text the parsing prompt receives.
///
/// The extractor walks the DOM in document order and emits one line per
/// block of visible text, plus tagged lines for what a text walk would
/// miss: `[META]` (OpenGraph/description), `[IMAGE]`, `[ANCHOR]` and
/// `[IFRAME]`. It reads `<td>`, `<time>`, `<section>` and every other
/// element alike, decodes the page by its real charset (EUC-KR included),
/// resolves relative URLs against the final URL after redirects and follows
/// one level of same-host iframes — the gaps the eval set exposed
/// (`docs/PARSING_EVAL.md` §6).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import 'euc_kr.dart';

/// True when [text] contains at least one Hangul syllable.
bool containsKorean(String text) => RegExp(r'[가-힣]').hasMatch(text);

/// A fetched page: the decoded HTML and the URL it was finally served from.
class FetchedPage {
  final String html;
  final Uri finalUri;

  const FetchedPage(this.html, this.finalUri);
}

const int _maxRedirects = 5;
const Duration _defaultTimeout = Duration(seconds: 15);

/// Upper bound on a page body; anything past it is dropped. Invitation
/// pages are tens of KB, so this only guards against a misbehaving host.
const int _maxBodyBytes = 4 << 20;

/// Fetches [url], following up to five redirects by hand so that the final
/// URL is known — relative image and iframe URLs resolve against it, and a
/// vendor's short link is not the page's real base. Returns `null` on any
/// network error or a non-200 status.
///
/// [timeout] bounds each hop twice: once for the headers and once for
/// reading the body, so a server that keeps the connection open after
/// the headers cannot stall the parser.
/// When [sameOriginAs] is set, every hop — the request itself and any
/// redirect target — must share that origin (scheme, host and port), or
/// the fetch is abandoned. Page fetches leave it unset because vendor
/// short links legitimately redirect across origins; subresource fetches
/// (script bundles, their JSON) set it so a redirect cannot pull local or
/// third-party content into the prompt.
Future<FetchedPage?> fetchPage(String url,
    {http.Client? client,
    Duration timeout = _defaultTimeout,
    Uri? sameOriginAs}) async {
  final raw = await _fetchRaw(url,
      client: client, timeout: timeout, sameOriginAs: sameOriginAs);
  if (raw == null) return null;
  return FetchedPage(decodeBody(raw.bytes, raw.contentType), raw.finalUri);
}

/// A fetched body before any decoding: the bytes, the URL they came from
/// and the declared content type.
class _RawResponse {
  final List<int> bytes;
  final Uri finalUri;
  final String? contentType;

  const _RawResponse(this.bytes, this.finalUri, this.contentType);
}

/// The redirect-following fetch both [fetchPage] and [fetchImage] share.
/// Text callers decode the bytes by charset; image callers keep them raw.
Future<_RawResponse?> _fetchRaw(String url,
    {http.Client? client,
    Duration timeout = _defaultTimeout,
    Uri? sameOriginAs}) async {
  final owned = client == null;
  final c = client ?? http.Client();
  try {
    var uri = Uri.parse(url);
    for (var hop = 0; hop <= _maxRedirects; hop++) {
      if (sameOriginAs != null && uri.origin != sameOriginAs.origin) {
        return null;
      }
      final request = http.Request('GET', uri)
        ..followRedirects = false
        ..headers['User-Agent'] =
            'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
                'AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 chungmo';
      final streamed = await c.send(request).timeout(timeout);
      // Decide on the headers alone; a redirect's body is never read.
      if (streamed.isRedirect || streamed.statusCode ~/ 100 == 3) {
        final location = streamed.headers['location'];
        if (location == null) return null;
        uri = uri.resolve(location);
        continue;
      }
      if (streamed.statusCode != 200) return null;
      final bytes = await _readBody(streamed.stream, timeout);
      return _RawResponse(bytes, uri, streamed.headers['content-type']);
    }
    return null;
  } catch (_) {
    return null;
  } finally {
    if (owned) c.close();
  }
}

/// Collects [stream] into bytes, giving up after [timeout] and truncating
/// at [_maxBodyBytes]. The subscription is cancelled on both exits, so a
/// never-ending body does not keep the connection alive.
Future<List<int>> _readBody(Stream<List<int>> stream, Duration timeout) {
  final completer = Completer<List<int>>();
  final bytes = <int>[];
  late final StreamSubscription<List<int>> sub;
  void finish() {
    if (!completer.isCompleted) completer.complete(bytes);
    sub.cancel();
  }

  sub = stream.listen(
      (chunk) {
        final room = _maxBodyBytes - bytes.length;
        if (chunk.length >= room) {
          bytes.addAll(chunk.take(room));
          finish();
          return;
        }
        bytes.addAll(chunk);
      },
      onDone: finish,
      onError: (Object e) {
        if (!completer.isCompleted) completer.completeError(e);
        sub.cancel();
      },
      cancelOnError: true);
  return completer.future.timeout(timeout, onTimeout: () {
    sub.cancel();
    throw TimeoutException('body read exceeded $timeout');
  });
}

/// Decodes [bytes] using the charset from [contentType], else from a
/// `<meta charset>` / `http-equiv` declaration in the document head, else
/// UTF-8. `dart:convert` only knows UTF-8, Latin-1 and ASCII; EUC-KR/CP949,
/// which ASP-era Korean vendors still serve, comes from `euc_kr.dart`.
String decodeBody(List<int> bytes, String? contentType) {
  var name = _charsetParam(contentType);
  if (name == null) {
    // Sniff the declaration in the head; ASCII-safe for every charset
    // that matters here.
    final head = latin1.decode(
        bytes.length > 4096 ? bytes.sublist(0, 4096) : bytes,
        allowInvalid: true);
    final meta = RegExp(r'''<meta[^>]+charset\s*=\s*["']?\s*([\w-]+)''',
            caseSensitive: false)
        .firstMatch(head);
    name = meta?.group(1);
  }
  final n = name?.trim().toLowerCase();
  if (n != null && _eucKrNames.contains(n)) return decodeEucKr(bytes);
  final encoding = n == null ? null : Encoding.getByName(n);
  if (encoding == null || encoding == utf8) {
    return const Utf8Decoder(allowMalformed: true).convert(bytes);
  }
  try {
    return encoding.decode(bytes);
  } catch (_) {
    return const Utf8Decoder(allowMalformed: true).convert(bytes);
  }
}

const _eucKrNames = {
  'euc-kr',
  'euckr',
  'euc_kr',
  'cp949',
  'cp-949',
  'ms949',
  'windows-949',
  'ks_c_5601-1987',
  'ksc5601',
  'korean',
};

String? _charsetParam(String? contentType) {
  if (contentType == null) return null;
  final m = RegExp(r'''charset\s*=\s*["']?([\w-]+)''', caseSensitive: false)
      .firstMatch(contentType);
  return m?.group(1);
}

/// What a crawl produced: the prompt text, and the page's images in the
/// order a reader meets them (`og:image` first, then document order).
///
/// The images are carried separately from [text] — which already names them
/// on `[IMAGE]` lines — so a caller can hand them to the multimodal parser
/// when the page turns out to be a picture of an invitation rather than an
/// invitation in text.
class CrawledInvitation {
  final String text;
  final List<Uri> images;

  const CrawledInvitation(this.text, this.images);
}

/// Crawls [url]; `null` when the page cannot be fetched. Same-host iframes
/// are fetched once and appended.
Future<CrawledInvitation?> crawlInvitation(String url,
    {http.Client? client}) async {
  final owned = client == null;
  final c = client ?? http.Client();
  try {
    final page = await fetchPage(url, client: c);
    if (page == null || page.html.isEmpty) return null;
    final extracted = extractContentFromHtml(page.html, page.finalUri);
    final images = <Uri>[...extracted.images];
    final buffer = StringBuffer(extracted.text);
    final frames = extracted.iframes
        .where((f) => f.host == page.finalUri.host)
        .toSet()
        .take(_maxIframes);
    for (final frame in frames) {
      final inner = await fetchPage(frame.toString(), client: c);
      if (inner == null || inner.html.isEmpty) continue;
      final innerContent = extractContentFromHtml(inner.html, inner.finalUri);
      // An embed carrying the whole invitation carries its images too.
      images.addAll(innerContent.images);
      if (innerContent.text.isEmpty) continue;
      buffer
        ..writeln()
        ..writeln('[IFRAME] $frame')
        ..write(innerContent.text);
    }
    // CSR shell fallback: a page whose rendered HTML carries almost no
    // text usually builds itself at runtime from a same-origin JSON that
    // its bundle fetches (static-export SPA vendors). Follow the bundle's
    // JSON references once, the same way same-host iframes are followed.
    if (buffer.length < _csrShellTextThreshold) {
      final origin = page.finalUri;
      final scripts = extracted.scripts
          .where((s) => s.origin == origin.origin)
          .toSet()
          .take(_maxScripts);
      final seen = <Uri>{};
      for (final script in scripts) {
        final js =
            await fetchPage(script.toString(), client: c, sameOriginAs: origin);
        if (js == null || js.html.isEmpty) continue;
        for (final match in _jsonRefPattern.allMatches(js.html)) {
          if (seen.length >= _maxDataFiles) break;
          final Uri ref;
          try {
            ref = script.resolve(match.group(1)!);
          } catch (_) {
            continue;
          }
          if (ref.origin != origin.origin || !seen.add(ref)) continue;
          final data =
              await fetchPage(ref.toString(), client: c, sameOriginAs: origin);
          if (data == null || data.html.isEmpty) continue;
          final capped = data.html.length > _maxScriptChars
              ? data.html.substring(0, _maxScriptChars)
              : data.html;
          buffer
            ..writeln()
            ..writeln('[DATA] $ref')
            ..write(capped);
        }
      }
    }
    return CrawledInvitation(
        buffer.toString(), images.toSet().toList(growable: false));
  } finally {
    if (owned) c.close();
  }
}

/// Number of Hangul syllables in [text].
///
/// How much Korean a crawl produced separates an invitation written in text
/// from one that is only a stack of pictures far better than a raw character
/// count does, because `[IMAGE]`/`[ANCHOR]` lines are long URLs that inflate
/// the latter. Measured over the eval set, the image-only fixtures land at 33
/// while the lowest text-bearing case sits at 53 and the median near 260.
int hangulLength(String text) => _hangul.allMatches(text).length;

final RegExp _hangul = RegExp(r'[가-힣]');

/// Below this many Hangul syllables, a page is treated as carrying too
/// little Korean to parse from text alone and its images are attached to
/// the prompt as well. Set above the image-only fixtures (33) and below the
/// lowest text-bearing case (53), with the crawl text kept in the prompt
/// either way so that a false positive costs an upload, never an answer.
const int _textPoorHangulThreshold = 45;

/// Whether [crawled] should also be parsed as pictures.
bool needsImageFallback(CrawledInvitation crawled) =>
    crawled.images.isNotEmpty &&
    hangulLength(crawled.text) < _textPoorHangulThreshold;

/// An image downloaded for the multimodal fallback.
class FetchedImage {
  final Uint8List bytes;
  final String mimeType;
  final Uri uri;

  const FetchedImage(this.bytes, this.mimeType, this.uri);
}

/// MIME types Gemini accepts as image parts. GIF and SVG are left out: the
/// model rejects them, and an SVG is markup the crawler has already read.
const _imageMimeTypes = {'image/jpeg', 'image/png', 'image/webp'};

/// Smallest image worth sending. Icons, bullets, spacers and sprites sit
/// far below this; an invitation section rendered as a picture sits far
/// above it. Judged on the downloaded bytes rather than on the file name,
/// so no vendor's naming convention has to be guessed at.
const int _minImageBytes = 10 << 10;

/// Downloads up to [max] usable images from [urls], in order.
///
/// At most [attempts] URLs are tried, so a page leading with a row of icons
/// cannot turn one parse into a dozen round trips. Anything that fails to
/// download, is too small, or is not a format the model reads is skipped.
Future<List<FetchedImage>> fetchInvitationImages(
  List<Uri> urls, {
  http.Client? client,
  int max = _maxFallbackImages,
  int attempts = _maxImageAttempts,
  Duration timeout = _defaultTimeout,
}) async {
  if (urls.isEmpty || max <= 0) return const [];
  final owned = client == null;
  final c = client ?? http.Client();
  final found = <FetchedImage>[];
  try {
    var tried = 0;
    for (final url in urls) {
      if (found.length >= max || tried >= attempts) break;
      if (url.scheme != 'http' && url.scheme != 'https') continue;
      tried++;
      final image = await fetchImage(url, client: c, timeout: timeout);
      if (image != null) found.add(image);
    }
    return found;
  } finally {
    if (owned) c.close();
  }
}

/// Downloads one image; `null` when it cannot be fetched, is too small to
/// be content, or is not a format the model reads.
Future<FetchedImage?> fetchImage(Uri url,
    {http.Client? client, Duration timeout = _defaultTimeout}) async {
  final raw =
      await _fetchRaw(url.toString(), client: client, timeout: timeout);
  if (raw == null || raw.bytes.length < _minImageBytes) return null;
  final mimeType = _imageMimeType(raw.bytes, raw.contentType);
  if (mimeType == null) return null;
  return FetchedImage(
      Uint8List.fromList(raw.bytes), mimeType, raw.finalUri);
}

/// The image type of [bytes], preferring the magic number over the declared
/// [contentType] — vendors serve images as `application/octet-stream` and
/// occasionally mislabel them outright.
String? _imageMimeType(List<int> bytes, String? contentType) {
  if (bytes.length >= 12) {
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    // RIFF....WEBP
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
  }
  final declared = contentType?.split(';').first.trim().toLowerCase();
  return _imageMimeTypes.contains(declared) ? declared : null;
}

const int _maxIframes = 2;
const int _maxScriptChars = 6000;
const int _maxOutputChars = 30000;

/// Below this many characters of extracted text, a page is treated as a
/// client-rendered shell and its bundle's JSON references are followed.
const int _csrShellTextThreshold = 600;
const int _maxScripts = 2;
const int _maxDataFiles = 2;

/// How many images the multimodal fallback sends, and how many URLs it may
/// try to find them.
///
/// An image-only invitation is not one picture: vendors cut it into a cover
/// photo and a panel per section — greeting, date and venue, directions,
/// accounts — so a cap of two or three reads the couple's names and misses
/// where to send the money. Five covers the sections while the attempt cap
/// keeps a page that leads with a row of decorative images from turning one
/// parse into a dozen round trips.
const int _maxFallbackImages = 5;
const int _maxImageAttempts = 8;

/// A JSON resource mentioned inside a script bundle, e.g. fetch('./data.json').
final RegExp _jsonRefPattern =
    RegExp('''['"]([^'"\\s]+\\.json(?:\\?[^'"\\s]*)?)['"]''');

/// What [extractContentFromHtml] found: the prompt text, the iframe
/// sources, the external script bundles the caller may want to follow and
/// the page's images in reading order.
class ExtractedContent {
  final String text;
  final List<Uri> iframes;
  final List<Uri> scripts;
  final List<Uri> images;

  const ExtractedContent(this.text, this.iframes,
      [this.scripts = const [], this.images = const []]);
}

/// Pure extraction from an HTML string, with URLs resolved against [base].
/// Exposed for tests and for the eval runner's `--crawl-only` mode.
ExtractedContent extractContentFromHtml(String html, Uri base) {
  final doc = html_parser.parse(html);
  final walker = _Walker(_documentBase(doc, base));
  final title = doc.querySelector('title')?.text.trim();
  if (title != null && title.isNotEmpty) walker._emit(title);
  walker._emitMeta(doc);
  // Walk the whole document, not just <body>: JSON-LD, framework state
  // and vendors' inline scripts often sit in <head>. Title and meta are
  // emitted above and skipped by the walker.
  final root = doc.documentElement;
  if (root != null) walker._walk(root);
  walker._flush();
  return ExtractedContent(
      walker._output(), walker.iframes, walker.scripts, walker.images);
}

/// The first valid `<base href>` resolved against [fetched], else
/// [fetched] itself — the same rule browsers use for relative URLs.
Uri _documentBase(Document doc, Uri fetched) {
  for (final el in doc.querySelectorAll('base[href]')) {
    final href = el.attributes['href']?.trim();
    if (href == null || href.isEmpty) continue;
    try {
      return fetched.resolve(href);
    } catch (_) {
      continue;
    }
  }
  return fetched;
}

const _skippedTags = {
  'style',
  'noscript',
  'svg',
  'template',
  'title',
  'meta',
  'link',
  'base',
  'select',
  'option',
};

/// Elements that end a line of visible text.
const _blockTags = {
  'p',
  'div',
  'section',
  'article',
  'header',
  'footer',
  'main',
  'nav',
  'aside',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'li',
  'ul',
  'ol',
  'dl',
  'dt',
  'dd',
  'table',
  'thead',
  'tbody',
  'tr',
  'td',
  'th',
  'caption',
  'figure',
  'figcaption',
  'blockquote',
  'pre',
  'address',
  'form',
  'fieldset',
  'button',
  'details',
  'summary',
  'hr',
  'center',
};

const _metaKeys = {
  'og:title',
  'og:description',
  'og:image',
  'og:image:url',
  'og:url',
  'twitter:title',
  'twitter:description',
  'twitter:image',
  'description',
  'title',
};

class _Walker {
  final Uri base;
  final List<String> _lines = [];
  final Set<String> _seen = {};
  final List<Uri> iframes = [];
  final List<Uri> scripts = [];
  final List<Uri> images = [];
  final StringBuffer _current = StringBuffer();

  _Walker(this.base);

  void _emitMeta(Document doc) {
    for (final meta in doc.querySelectorAll('meta')) {
      final key = (meta.attributes['property'] ?? meta.attributes['name'])
          ?.trim()
          .toLowerCase();
      final content = meta.attributes['content']?.trim();
      if (key == null || content == null || content.isEmpty) continue;
      if (!_metaKeys.contains(key)) continue;
      final bool isImage = key.endsWith('image') || key.endsWith('image:url');
      final value = isImage || key == 'og:url' ? _resolve(content) : content;
      // The share-card image is the one picture a vendor guarantees is the
      // invitation itself, so it leads the list the fallback reads from.
      if (isImage) _collectImage(value);
      _emit('[META] $key → $value');
    }
  }

  void _walk(Node node) {
    if (node is Text) {
      _current.write(node.data);
      return;
    }
    if (node is! Element) return;
    final tag = node.localName ?? '';
    if (_skippedTags.contains(tag)) return;
    // Elements hidden by an inline style still carry the text a user sees
    // after tapping a button (account details, modals), so they are kept.
    switch (tag) {
      case 'br':
        _flush();
        return;
      case 'script':
        _flush();
        _emitScript(node);
        return;
      case 'img':
        _flush();
        final src = _imageSource(node);
        if (src != null) {
          _emit('[IMAGE] $src');
          _collectImage(src);
        }
        return;
      case 'iframe':
        _flush();
        final src = node.attributes['src']?.trim();
        if (src != null && src.isNotEmpty && !src.startsWith('about:')) {
          final uri = _resolveUri(src);
          if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
            iframes.add(uri);
            _emit('[IFRAME] $uri');
          }
        }
        return;
      case 'a':
        _flush();
        final href = node.attributes['href']?.trim() ?? '';
        final text = _collapse(node.text);
        if (href.isEmpty || href.startsWith('javascript:') || href == '#') {
          if (text.isNotEmpty) _emit(text);
        } else {
          _emit(text.isEmpty
              ? '[ANCHOR] ${_resolve(href)}'
              : '[ANCHOR] $text → ${_resolve(href)}');
        }
        return;
    }
    final block = _blockTags.contains(tag);
    if (block) _flush();
    for (final child in node.nodes) {
      _walk(child);
    }
    if (block) _flush();
  }

  /// Inline scripts are kept when they carry data rather than code: JSON-LD
  /// and framework state blobs, or anything with Korean text in it (vendor
  /// pages stash strings there), capped so one bundle cannot flood the
  /// prompt.
  void _emitScript(Element script) {
    final src = script.attributes['src']?.trim();
    if (src != null) {
      if (src.isNotEmpty) {
        final uri = _resolveUri(src);
        if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
          scripts.add(uri);
        }
      }
      return;
    }
    final type = script.attributes['type']?.toLowerCase() ?? '';
    final id = script.attributes['id'] ?? '';
    final text = script.text.trim();
    if (text.isEmpty) return;
    final isData = type == 'application/ld+json' ||
        type == 'application/json' ||
        id == '__NEXT_DATA__' ||
        text.startsWith('window.__NUXT__') ||
        text.startsWith('window.__INITIAL_STATE__');
    if (!isData && !containsKorean(text)) return;
    final capped = text.length > _maxScriptChars
        ? text.substring(0, _maxScriptChars)
        : text;
    _emit('[SCRIPT] ${_collapse(capped)}');
  }

  /// Real image URL: `src` unless it is a lazy-loading placeholder, in
  /// which case the usual data attributes and `srcset` are tried.
  String? _imageSource(Element img) {
    final candidates = [
      img.attributes['src'],
      img.attributes['data-src'],
      img.attributes['data-original'],
      img.attributes['data-lazy-src'],
      img.attributes['data-lazy'],
      img.attributes['data-url'],
      img.attributes['srcset']?.split(',').first.trim().split(' ').first,
    ];
    for (final c in candidates) {
      final v = c?.trim();
      if (v == null || v.isEmpty || v.startsWith('data:')) continue;
      return _resolve(v);
    }
    return null;
  }

  /// Records a resolved image URL once, keeping reading order. Data URIs
  /// never reach here ([_imageSource] drops them) and anything that is not
  /// an http(s) URL is of no use to the fallback.
  void _collectImage(String resolved) {
    final uri = _resolveUri(resolved);
    if (uri == null) return;
    if (uri.scheme != 'http' && uri.scheme != 'https') return;
    if (images.contains(uri)) return;
    images.add(uri);
  }

  Uri? _resolveUri(String ref) {
    try {
      return base.resolve(ref);
    } catch (_) {
      return null;
    }
  }

  /// Resolved URL with percent-encoding undone, so a venue name inside a
  /// map link stays readable Korean for the model.
  String _resolve(String ref) {
    final resolved = _resolveUri(ref)?.toString() ?? ref;
    try {
      return Uri.decodeFull(resolved);
    } catch (_) {
      return resolved;
    }
  }

  void _flush() {
    final text = _collapse(_current.toString());
    _current.clear();
    if (text.length < 2) return;
    _emit(text);
  }

  void _emit(String line) {
    if (_seen.add(line)) _lines.add(line);
  }

  String _output() {
    final joined = _lines.join('\n');
    return joined.length > _maxOutputChars
        ? joined.substring(0, _maxOutputChars)
        : joined;
  }

  static String _collapse(String s) =>
      s.replaceAll(RegExp(r'[\s ]+'), ' ').trim();
}
