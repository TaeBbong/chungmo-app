<!-- docs/CRAWLER_COVERAGE.md -->

# Reading What the Page Actually Contains: the Link Crawler Rewrite

How chungmo's link crawler went from "query a few tag names and sort the
lines" to a document-order text walk with real charset handling, and what
that did to the parser's accuracy. Written as a working reference: each
section is concept → the actual code in this repo → why it is shaped that
way.

---

## 1. The problem: a filter in front of the model

The link pipeline is `crawler → text → Gemini`. Whatever the crawler drops
is gone; no prompt can recover it. The eval set (`docs/PARSING_EVAL.md`)
made that measurable: on 40 fixtures, 11 lost at least one required field
*before* the prompt was built, and the model's `core` accuracy was 63% —
100% of the `hard` cases failing at the crawler, not at the model.

The old extractor did three things that looked reasonable and were not:

```dart
doc.querySelectorAll('p, h1, h2, h3, h4, h5, h6, li, div, script, meta, title')
```

- It read `element.text` of every match. A `<div>` containing three
  `<p>`s emits its text *and* each `<p>` emits it again, so the prompt was
  full of duplicates — while `<td>`, `<time>`, `<section>` and
  `<span>`-only layouts, none of which are in the list, were invisible.
- `<meta>` elements have no text, so the OpenGraph title/description/image
  that every SPA and image-only page carries yielded empty strings.
- The lines were `sort()`ed alphabetically before joining. "신랑측" and the
  accounts under it ended up paragraphs apart.

And two things outside the extractor: `http.get(...).body` decoded EUC-KR
pages as Latin-1 (so the Korean filter rejected every line), and relative
URLs were passed through verbatim.

---

## 2. Concept: visible-text extraction as a DOM walk

Browsers expose `innerText`: the text a user would see, with line breaks
where block elements start and end. That is the right model for a prompt:
one line per visible block, in document order, nothing repeated.
Implementing it is a depth-first walk with a line buffer:

```
walk(node):
  text node      → append to the current line
  <br>           → flush the line
  block element  → flush, walk children, flush
  inline element → walk children
  skipped tags (style, noscript, svg, title, meta, link, select)
                 → nothing
```

"Block" is the HTML notion (`p`, `div`, `section`, `td`, `li`, `h1`…),
plus a few that behave like blocks in invitations (`button`, `summary`,
`center`). Everything else — `span`, `b`, `time`, `font`, `a` — is inline
and simply contributes characters to the line it sits in. The nested-div
duplication disappears because text nodes are read once, at their own
position, regardless of how deep they are.

Some content is not visible text but still belongs in the prompt, so the
walk emits tagged lines for it at the position where it occurs:

| Tag | Source | Why the model needs it |
|---|---|---|
| `[META] og:description → …` | `<meta property/name>` with an allow-listed key | The only text a CSR shell or image-only page has |
| `[IMAGE] https://…/main.jpg` | `<img>` — `src`, or `data-src`/`srcset` when `src` is a `data:` placeholder | Thumbnail |
| `[ANCHOR] 카카오맵 → https://map.kakao.com/link/search/라온컨벤션` | `<a href>` (javascript:/# links emit their text only) | Venue names hide in map links |
| `[IFRAME] https://…/content.html` | `<iframe src>` | Also returned to the caller to fetch |
| `[SCRIPT] {"@type":"Event",…}` | JSON-LD, `application/json`, `__NEXT_DATA__`, `window.__NUXT__`, or any inline script containing Korean; capped at 6,000 chars | SSR frameworks duplicate the page as JSON with ISO dates |

Hidden elements (`style="display:none"`, Bootstrap modals, toggled account
blocks) are deliberately *kept*: they are what the user sees after a tap.
Deduplication is exact-line, first occurrence wins, so a header repeated in
a sticky bar appears once but order is preserved.

---

## 3. Concept: decoding by the declared charset

`package:http`'s `Response.body` picks its decoder with
`Encoding.getByName(charset)`, and `dart:convert` only knows UTF-8, Latin-1
and ASCII. For `charset=euc-kr` it silently falls back to Latin-1 and the
page becomes 1,000 lines of `¼ºÅÂ¾ç`. The rewrite works on `bodyBytes`:

```dart
String decodeBody(List<int> bytes, String? contentType) {
  var name = _charsetParam(contentType);           // 1. HTTP header
  name ??= sniffMetaCharset(first4KB(bytes));      // 2. <meta charset> / http-equiv
  if (_eucKrNames.contains(name)) return decodeEucKr(bytes);
  final encoding = Encoding.getByName(name);        // latin1 / ascii
  return encoding == null || encoding == utf8
      ? const Utf8Decoder(allowMalformed: true).convert(bytes)   // 3. lenient default
      : encoding.decode(bytes);
}
```

Order matters: the header is authoritative when present (a CDN that
re-declares UTF-8 wins over a stale meta tag, which is also what browsers
do), the meta tag covers servers that send no charset, and the default is
*lenient* UTF-8 so a stray byte never throws away the whole page.

### 3.1 A pure-Dart CP949 decoder

No usable EUC-KR codec exists on pub: the one candidate with a good score
produced wrong output in both directions when checked against Python's
`cp949` codec, and the others are Dart-2-only. Writing one is smaller than
it sounds because CP949 has structure:

| Byte range (lead × trail) | Content | Size |
|---|---|---|
| 0xA1–0xAC × 0xA1–0xFE | KS X 1001 symbols (`·`, `♥`, `☎`, circled numbers…) | 1,128 |
| 0xB0–0xC8 × 0xA1–0xFE | the 2,350 "common" Hangul syllables | 2,350 |
| 0xCA–0xFD × 0xA1–0xFE | Hanja | 4,888 |
| 0x81–0xC6 × 0x41–0x5A, 0x61–0x7A, 0x81–0xFE | UHC extension: every *other* syllable | 8,822 |

The first three are plain tables — `lib/core/utils/euc_kr.dart` stores them
as one Dart string per row, generated once from Python's codec (about 14 KB
of source). The fourth needs no table at all: the extension lists the
11,172 − 2,350 remaining syllables **in Unicode order**, so it is derived
lazily by iterating U+AC00…U+D7A3 and skipping whatever is in the 2,350
table. Position within the extension follows the trail ranges (178 slots
per lead up to 0xA0, 84 after).

The decoder is checked against reference vectors — symbols, common
syllables, extension syllables such as 뷁, Hanja and 300 random syllables
encoded by Python — in `test/core/utils/euc_kr_test.dart`.

---

## 4. Concept: the final URL is the base URL

`http.get` follows redirects, but the response does not tell you where it
ended up. A vendor short link (`/s/abc` → `/card/2026/kim-lee/`) makes
`./main.jpg` resolve to the wrong place, and the app would store a relative
path as the thumbnail. `fetchPage` therefore follows redirects by hand:

```dart
for (var hop = 0; hop <= 5; hop++) {
  final request = http.Request('GET', uri)..followRedirects = false;
  final response = await http.Response.fromStream(await client.send(request));
  if (response.isRedirect) { uri = uri.resolve(response.headers['location']!); continue; }
  return FetchedPage(decodeBody(response.bodyBytes, response.headers['content-type']), uri);
}
```

Every `src`/`href` is then `base.resolve(ref)` against that final URL, and
percent-decoded afterwards so a venue name inside a map link stays
readable Korean for the model (`…/search/라온컨벤션`, not
`%EB%9D%BC…`).

Iframes are the last hop: the walk collects their sources, and
`extractContentWithImages` fetches up to two of them on the same host and
appends their extraction under an `[IFRAME]` marker. Same host only,
because cross-origin frames are maps, videos and ads.

---

## 5. What it changed

Measured with `eval/run_eval.dart` on the same 40 fixtures, same model,
same prompt (`eval/results/latest.md`):

| | before | after |
|---|---|---|
| Crawl coverage (every field present in the text) | 68% | **90%** |
| `core` (schedule saves with no manual fix) | 63% | **85%** |
| easy / medium / hard | 93% / 79% / 0% | 100% / 86% / 64% |
| groom · bride | 90% · 90% | 100% · 100% |
| datetime · location · accounts | 68% · 83% · 83% | 90% · 95% · 93% |
| thumbnail | 73% | 100% |
| prompt tokens per page (mean) | ~990 | ~820 |

Templates that went from 0% to 100%: `euckr-asp` (charset), `table-legacy`
(td text), `iframe-embed` (follow), `tailwind-semantic` (`<time>` in a
`<header>`). The prompt also got *shorter* while carrying more, because the
duplicates are gone.

The six remaining failures are not crawler failures:

- `hanul-04`, `bs-03` — dates printed without a year; the model returns
  `null` because the prompt gives it no reference date (issue #50).
- `spa-01`, `spa-02` — account numbers live in `data.json`, which the HTML
  never mentions; OpenGraph carried the names, date and venue, so those
  now pass (issue #51 covers the rest).
- `img-01`, `img-02` — date, venue and accounts are pixels (issue #51).

---

## 6. Why not the alternatives

| Option | Why not |
|---|---|
| Add `td`, `span`, `time` to the selector list | Multiplies the duplication (every span *and* its parents) and still sorts the lines; the walk is simpler and correct by construction. |
| Strip all tags with a regex | Loses block boundaries ("일시13:30장소…"), keeps CSS/JS text, cannot tag images or meta. |
| `charset_converter` (platform codecs) | Flutter-only; the eval runner and unit tests run under plain `dart`, and the decoder must be identical in both. |
| Full WHATWG `index-euc-kr` table (17,048 entries) | Three tables plus the algorithmic extension are a fifth of the size and cover the same code points. |
| Headless browser for JS pages | Needs a server; out of scope here and tracked as the image fallback instead. |

---

## 7. Checklist when a new page type fails

1. `fvm dart run eval/run_eval.dart --crawl-only --only=<id>` and read
   `eval/results/crawl/<id>.txt`. If the value is missing there, it is a
   crawler gap; if present, a prompt/model gap.
2. For a crawler gap, add a minimal reproduction to
   `test/core/utils/crawler_test.dart` first — the fixture HTML is the spec.
3. Fix the walk (a new block tag, a new lazy-load attribute, a new script
   marker), rerun the test, then `--crawl-only` for the coverage ceiling
   and a full run for the model-side number.
