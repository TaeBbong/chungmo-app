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
const Duration _timeout = Duration(seconds: 15);

/// Fetches [url], following up to five redirects by hand so that the final
/// URL is known — relative image and iframe URLs resolve against it, and a
/// vendor's short link is not the page's real base. Returns `null` on any
/// network error or a non-200 status.
Future<FetchedPage?> fetchPage(String url, {http.Client? client}) async {
  final owned = client == null;
  final c = client ?? http.Client();
  try {
    var uri = Uri.parse(url);
    for (var hop = 0; hop <= _maxRedirects; hop++) {
      final request = http.Request('GET', uri)
        ..followRedirects = false
        ..headers['User-Agent'] =
            'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
                'AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 chungmo';
      final streamed = await c.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      if (response.isRedirect || response.statusCode ~/ 100 == 3) {
        final location = response.headers['location'];
        if (location == null) return null;
        uri = uri.resolve(location);
        continue;
      }
      if (response.statusCode != 200) return null;
      return FetchedPage(
          decodeBody(response.bodyBytes, response.headers['content-type']),
          uri);
    }
    return null;
  } catch (_) {
    return null;
  } finally {
    if (owned) c.close();
  }
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

/// Extracts the prompt text for [url]; `null` when the page cannot be
/// fetched. Same-host iframes are fetched once and appended.
Future<String?> extractContentWithImages(String url,
    {http.Client? client}) async {
  final owned = client == null;
  final c = client ?? http.Client();
  try {
    final page = await fetchPage(url, client: c);
    if (page == null || page.html.isEmpty) return null;
    final extracted = extractContentFromHtml(page.html, page.finalUri);
    final buffer = StringBuffer(extracted.text);
    for (final frame in extracted.iframes.take(_maxIframes)) {
      if (frame.host != page.finalUri.host) continue;
      final inner = await fetchPage(frame.toString(), client: c);
      if (inner == null || inner.html.isEmpty) continue;
      final innerText = extractContentFromHtml(inner.html, inner.finalUri).text;
      if (innerText.isEmpty) continue;
      buffer
        ..writeln()
        ..writeln('[IFRAME] $frame')
        ..write(innerText);
    }
    return buffer.toString();
  } finally {
    if (owned) c.close();
  }
}

const int _maxIframes = 2;
const int _maxScriptChars = 6000;
const int _maxOutputChars = 30000;

/// What [extractContentFromHtml] found: the prompt text and the iframe
/// sources the caller may want to follow.
class ExtractedContent {
  final String text;
  final List<Uri> iframes;

  const ExtractedContent(this.text, this.iframes);
}

/// Pure extraction from an HTML string, with URLs resolved against [base].
/// Exposed for tests and for the eval runner's `--crawl-only` mode.
ExtractedContent extractContentFromHtml(String html, Uri base) {
  final doc = html_parser.parse(html);
  final walker = _Walker(base);
  final title = doc.querySelector('title')?.text.trim();
  if (title != null && title.isNotEmpty) walker._emit(title);
  walker._emitMeta(doc);
  // Walk the whole document, not just <body>: JSON-LD, framework state
  // and vendors' inline scripts often sit in <head>. Title and meta are
  // emitted above and skipped by the walker.
  final root = doc.documentElement;
  if (root != null) walker._walk(root);
  walker._flush();
  return ExtractedContent(walker._output(), walker.iframes);
}

const _skippedTags = {
  'style',
  'noscript',
  'svg',
  'template',
  'title',
  'meta',
  'link',
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
      final value =
          key.endsWith('image') || key.endsWith('image:url') || key == 'og:url'
              ? _resolve(content)
              : content;
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
        if (src != null) _emit('[IMAGE] $src');
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
    if (script.attributes.containsKey('src')) return;
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
