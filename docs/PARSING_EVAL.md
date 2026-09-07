<!-- docs/PARSING_EVAL.md -->

# Measuring the Link Parser: A Hosted, Synthetic Eval Set

How chungmo measures the accuracy of "paste an invitation link → schedule"
without depending on real invitations that expire, and what the first run
revealed. Written as a working reference: each section is concept → the
actual code in this repo → why it is shaped that way.

---

## 1. The problem: a benchmark that rots

The link parser is the app's core feature, and until now its quality was
anecdotal: a handful of real invitation links tried by hand. Two things
make that unusable as a benchmark.

- **Real links expire.** Vendors take invitations down a few weeks after
  the wedding. A dataset of 30 real URLs is mostly dead within a season, so
  any number computed on it cannot be reproduced later.
- **The failure surface is the markup, not the wedding.** The model
  rarely fails because a couple's names are unusual; it fails because the
  page is client-rendered, encoded in EUC-KR, laid out in `<table>`s, or
  hides the account numbers behind a button. What needs to vary across the
  dataset is the *vendor's technical style*.

So the eval set is synthetic and hosted: 40 fictional weddings, each
rendered by one of 16 templates that imitate a kind of Korean
mobile-invitation vendor page, served from the project's own Firebase
Hosting site at stable URLs (`https://chung-mo.web.app/eval/<id>/`).
Nobody's real data is involved, and the pages will still be there in five
years.

---

## 2. What an LLM eval is

An *eval* is a fixed set of inputs with known correct outputs, a scoring
function that compares a system's answer to the expectation, and a runner
that reports aggregate rates. Three properties matter:

1. **Ground truth is authored once.** In this repo the expectations are
   not typed by hand into a spreadsheet: `eval/generate_fixtures.py` holds
   the fictional data, renders the HTML *and* writes `eval/dataset.json`
   from the same objects. The pages and the answer key cannot drift apart.
2. **The system under test is the shipped one.** The runner reuses the
   app's crawler and the app's prompt/schema verbatim (see §4). A benchmark
   of a slightly different prompt measures nothing.
3. **Scores are per field, then aggregated.** "72% accurate" is useless
   for engineering; "datetime is 60% because pages with no year confuse
   the model" is actionable. The scorer therefore reports each field and
   rolls them up by template, difficulty and tag.

There is one more idea that turned out to be the most valuable: a
**model-independent ceiling**. Before asking the model anything, check
whether the crawler's text even *contains* the expected values. A field
that never reached the prompt cannot be extracted by any prompt or model,
so this "crawl coverage" separates crawler defects from model defects.

---

## 3. The fixtures

### 3.1 Sixteen vendor styles

Each template reproduces the *technical* signature of a family of real
pages. No vendor's markup or assets were copied; the names and layouts are
original, the mechanisms are what real pages do.

| Template | What it imitates | Crawler-relevant trait |
|---|---|---|
| `classic-jquery` | 2015-era PHP vendor, jQuery + slick | div soup, `<br>`-heavy text, Korean strings in inline JS, a month calendar grid of distractor numbers |
| `euckr-asp` | ASP-era page | bytes in EUC-KR, served with `charset=euc-kr`; `<font>` and `align` |
| `table-legacy` | XHTML transitional | every text node inside `<td>`, no `<div>`/`<p>` |
| `nextjs-ssr` | Next.js SSR | hashed CSS-module classes, `__NEXT_DATA__` JSON duplicating the content |
| `csr-shell` | Vite/CRA SPA | empty `#root`, OpenGraph meta only; content fetched from `data.json` |
| `nuxt-ssr` | Nuxt 2 SSR | `data-v-*` attributes, `window.__NUXT__` state |
| `site-builder` | Website builders | deep nesting, inline styles, one `<span>` per word, lazy images (`data-src`) |
| `tailwind-semantic` | Modern semantic HTML | `<header>/<section>/<time>`, JSON-LD Event, `<details>` accordions, KakaoPay links |
| `styled-react` | React + styled-components | date as bare numerals with CSS `::before` separators |
| `wordpress-theme` | WordPress post | guestbook comments mentioning other dates and names |
| `bootstrap-2019` | Bootstrap 4 + jQuery | accounts inside a hidden modal, numbers without hyphens, a reception on another date/venue |
| `iframe-embed` | Shell + iframe | the outer page has nothing but an `<iframe>` |
| `image-only` | Image invitations | every section is an image; HTML has only `<img>` and OG meta |
| `kakao-card` | Messenger share card | accounts in `data-*` attributes and `display:none` blocks |
| `english-intl` | English invitation | romanised names, "Saturday, October 17, 2026 at 1:30 PM" |
| `notion-export` | Self-made Notion export | emoji headings, callouts, `<figure>` |

On top of the template, each case picks a **date style** (`2026년 10월 17일
토요일 오후 1시 30분`, `2026.10.17 (토) 13:30`, `10월 17일 토요일 오후 2시`
with no year, `2026-10-17 13:30`, `26.10.17 SAT PM 1:30`, English, or no
date at all) and an **account configuration** (none, one side, the couple,
the parents, everyone). Two cases are reached through a short-link
redirect and one through a rewrite, because vendors do that too.

### 3.2 Hosting rules

The fixtures ride on the same `firebase.json` as the policy pages
(`docs/FIREBASE_HOSTING.md`). The generator emits `eval/hosting_rules.json`,
merged into the `hosting` section:

```json
"redirects": [{ "source": "/eval/s/agfudwwt", "destination": "/eval/hanul-03/", "type": 301 }],
"rewrites":  [{ "source": "/eval/w/ynmtmdm", "destination": "/eval/bs-03/index.html" }],
"headers":   [{ "source": "/eval/euckr-*/", "headers": [{ "key": "Content-Type", "value": "text/html; charset=euc-kr" }] }]
```

Two lessons from getting this to work:

- `trailingSlash: false` broke every fixture. Firebase redirected
  `/eval/x/` to `/eval/x`, and the pages' relative `./main.svg` then
  resolved against `/eval/`. Directory-index pages need the slash, so the
  policy pages got explicit `/privacy/ → /privacy` redirects instead.
- A `Content-Type` override applies to whatever the glob matches. The first
  glob (`/eval/euckr-*/**`) also served the SVG next to the page as
  `text/html`, which the browser refused to draw. The rule now names the
  HTML paths only.

### 3.3 Regenerating

```bash
python3 eval/generate_fixtures.py          # rewrites hosting/public/eval and eval/dataset.json
# merge eval/hosting_rules.json into firebase.json (redirects/rewrites/headers)
firebase deploy --only hosting --project chung-mo
```

The catalogue at `https://chung-mo.web.app/eval/` lists every case with its
tags and expected values.

---

## 4. The runner

`eval/run_eval.dart` is a plain Dart script (`fvm dart run
eval/run_eval.dart`) that rebuilds the app's link pipeline outside Flutter:

```dart
final parsed = await extractContentWithImages(url);          // lib/core/utils/crawler.dart
final raw = await _generate(linkExtractionPrompt(parsed), …); // lib/data/sources/remote/invitation_prompt.dart
final predicted = jsonDecode(raw);
result['score'] = scoreCase(expected, predicted, pageUrl: Uri.parse(url)).toJson();
```

Making that possible required one refactor in the app: the prompt text and
the JSON schema moved out of `FirebaseAiLogicImpl` into
`invitation_prompt.dart`, a file with no Flutter or Firebase imports. The
app calls `linkExtractionPrompt`/`scheduleResponseJsonSchema` exactly as
before; the runner imports the same symbols. Only the transport differs:
the app goes through Firebase AI Logic (App Check, device attestation), the
runner calls the Gemini REST API with `GEMINI_API_KEY`, sending the schema
as `generationConfig.responseJsonSchema` — the same field the Firebase SDK
sends.

Runner options that matter day to day:

```
--crawl-only            no model; only crawl and compute coverage
--only=hanul-01,spa-02  a subset (writes to results/history, never latest.*)
--tag=csr               every case carrying a tag
--label="after td fix"  stored in the report for before/after comparisons
--base-url=http://localhost:5000   point at the hosting emulator
--rescore=eval/results/history/<run>.json   re-apply the scorer to saved predictions
```

`--rescore` exists because scorers have bugs too: the first run marked two
thumbnails wrong because a relative `./main.svg` behind a short-link
redirect was resolved against the short URL. Fixing the scorer and
re-scoring the saved predictions costs nothing; re-running the model would
have cost forty calls and introduced noise.

A full run writes `eval/results/latest.json` (raw predictions, timings,
token counts) and `eval/results/latest.md` (the tables). Partial or
crawl-only runs only write under `results/history/` so a filtered run can
never masquerade as the reference number. A preflight request validates
the key and model name before any case runs, for the same reason.

---

## 5. Scoring (`eval/scoring.dart`)

| Field | Rule |
|---|---|
| groom / bride | exact match after stripping whitespace, punctuation and role prefixes ("신랑 김민준"); English pages carry romanised aliases. A *lenient* rate (given name only) is reported separately, never counted as correct. |
| datetime | same instant at minute precision; a prediction without an offset is read as KST. A `null` expectation (no-date invitation) is met only by an empty prediction — the prompt says "never invent a date", and this checks it. |
| location | every expected keyword (the venue name) appears in the prediction, whitespace-insensitive. Hall and address are free text and are not scored. |
| accounts | the predicted set of `side|bank|number` keys equals the expected set. Banks are canonicalised (`KB국민은행` → `국민`), numbers reduced to digits, so formatting never counts as an error but a wrong side or a missing parent account does. Precision/recall are reported alongside. |
| thumbnail | resolves (relative to the page URL) to the main photo. Cosmetic, excluded from `core`. |

`core` is the app's notion of success: groom, bride, datetime, location and
accounts all correct, so the schedule saves with no manual fix. The
Markdown report breaks every rate down by difficulty, template and tag,
and lists each case's mismatches verbatim.

`crawlCoverage` is the model-independent ceiling from §2: whether the
crawler's text contains the expected groom, bride, date text, venue name
and every account number (digits only). It is computed on every run and in
`--crawl-only` mode, which needs no API key.

The scorer has unit tests in `test/eval/scoring_test.dart`.

---

## 6. First results: what the crawler drops before the model sees it

The crawl-coverage run (no model involved) on the 40 fixtures:

| group | n | all fields | groom | bride | date | location | accounts |
|---|---|---|---|---|---|---|---|
| **overall** | 40 | **68%** | 95% | 95% | 68% | 78% | 83% |
| classic-jquery, bootstrap-2019, kakao-card, nextjs-ssr, nuxt-ssr, site-builder, wordpress-theme, styled-react, english-intl, notion-export | 26 | 100% | | | | | |
| tailwind-semantic | 3 | 33% | ✓ | ✓ | ✗ | ✓ | ✓ |
| csr-shell | 3 | 0% | title only | | ✗ | ✗ | |
| euckr-asp | 2 | 0% | ✗ | ✗ | ✗ | ✗ | ✗ |
| table-legacy | 2 | 0% | title only | | ✗ | anchor only | ✗ |
| iframe-embed | 2 | 0% | title only | | ✗ | ✗ | ✗ |
| image-only | 2 | 0% | title only | | ✗ | ✗ | ✗ |

Roughly a third of the pages lose at least one required field *before the
prompt is built*. Reading the crawler (`lib/core/utils/crawler.dart`)
against the failing templates explains each one:

1. **`<meta>` content is never read.** `extractTextContent` collects
   `element.text` of `meta` elements, which is empty; the OpenGraph
   title/description/image that every SPA and image-only page carries is
   discarded. This alone would recover names and often the date and venue
   on `csr-shell` and `image-only`, and the thumbnail everywhere.
2. **The selector list misses HTML5 and table elements.** Only `p, h1–h6,
   li, div, script, meta, title` are queried. Text that lives in `<td>`
   without a `<div>` ancestor (`table-legacy`), or in `<time>` inside a
   `<header>`/`<section>` (`tailwind-semantic`), is invisible.
3. **EUC-KR is decoded as Latin-1.** `package:http` only knows UTF-8,
   Latin-1 and ASCII; for `charset=euc-kr` it silently falls back to
   Latin-1, so `containsKorean` rejects every line. Real ASP-era vendors
   (the probe in §7 found one) serve exactly this.
4. **Lazy images and relative URLs.** `src` is taken verbatim, so a
   `data:` placeholder wins over `data-src`, and `./main.svg` reaches the
   model as-is; the app would then try to load a relative path as the
   thumbnail.
5. **Iframes are not followed.** The outer page yields a title and a
   share button.
6. **`[LINK]` lines are dead code.** `link` elements are removed before
   `extractMediaContent` runs.

None of these is a model problem, which is the point of measuring the
ceiling first. The follow-up is tracked in `TODO.md` (crawler coverage);
after each fix, `--crawl-only` shows the new ceiling in seconds and a full
run shows what the model makes of it.

### 6.1 Model-side baseline (gemini-2.5-flash, unchanged crawler)

| core | groom | bride | datetime | location | accounts | thumbnail |
|---|---|---|---|---|---|---|
| **63%** | 90% | 90% | 68% | 83% | 83% | 73% |

| difficulty | n | core |
|---|---|---|
| easy | 15 | 93% |
| medium | 14 | 79% |
| hard | 11 | 0% |

Mean model latency 5.2 s per case, ~1,000 prompt tokens per page. The full
tables and every mismatch are in `eval/results/latest.md`; the run is
reproducible with `fvm dart run eval/run_eval.dart`.

Read against the coverage table, the 63% splits cleanly:

- **Every `hard` case fails at the crawler**, before the model. The 11
  cases (CSR shells, EUC-KR, tables, iframes, image-only) are exactly the
  ones with 0% coverage. Names still come out right on most of them because
  the `<title>` carries "김민준 ♥ 이서연" — which is why groom/bride sit at
  90% while datetime is 68%.
- **Where the crawler delivers everything, the model is at 93%.** Its own
  failures are two patterns, both prompt-level:
  - *Dates without a year* (`10월 24일 토요일 낮 12시 30분`) come back
    empty. The prompt says "never invent a date" and gives no reference
    date, so the model has no basis for choosing 2026 over 2025 and gives
    up. Two cases (`hanul-04`, `bs-03`); the app would fall into the
    manual-completion flow. A "today is …; a date without a year means the
    next occurrence" line is the obvious fix.
  - *Given names only* (`민석` for 이민석) on two pages whose hero prints
    the full names but whose greeting says "이영수 · 김미숙의 장남 민석".
    Both are lenient matches; the prompt should ask for the full name when
    the page shows one.
- **Thumbnails**: the model returns an empty string on a third of the
  pages even though `[IMAGE] ./main.svg` is in the text, and a relative
  path on the rest. Cosmetic, but the crawler should resolve URLs and the
  prompt should say the first large photo is the thumbnail.

Together this puts the ceiling after the listed crawler fixes at roughly
the `easy`+`medium` level for the whole set, and the prompt fixes above
are worth a few more points on top.

### 6.2 After the crawler rewrite (layer 1)

The rewrite described in `docs/CRAWLER_COVERAGE.md` (document-order text
walk, meta content, CP949 decoding, resolved URLs, iframe follow) moved
the same benchmark, same model, same prompt to:

| | before | after |
|---|---|---|
| crawl coverage | 68% | **90%** |
| core | 63% | **85%** |
| easy / medium / hard | 93% / 79% / 0% | 100% / 86% / 64% |
| groom · bride · datetime · location · accounts · thumbnail | 90 · 90 · 68 · 83 · 83 · 73 | 100 · 100 · 90 · 95 · 93 · 100 |

The six cases still failing are the two year-less dates (prompt, issue
#50) and the four whose data is not in the HTML at all — accounts behind a
CSR shell and image-only pages (image fallback, issue #51).

---

## 7. Why not the alternatives

| Option | Why not |
|---|---|
| Real invitation links | Expire within months; cannot be redistributed; the technical variety is whatever happened to be in the author's KakaoTalk. |
| Cloning vendor sample pages | Copyrighted markup and photos on a public host; also, samples are demo data that vendors change. |
| Local files / emulator only | Relative URLs, redirects, rewrites and charset headers are part of what fails in the field; they need a real HTTP server. The runner can still target the emulator with `--base-url`. |
| Scoring with an LLM judge | The fields are structured; exact and canonicalised comparison is cheaper, deterministic and explains every failure. |

---

## 8. Checklist for adding a case

1. Add a row to `CASES` in `eval/generate_fixtures.py` (template, date
   style, account configuration, quirks). A new *template* is a function
   returning `{filename: content}` plus a `TEMPLATE_NOTES` entry.
2. `python3 eval/generate_fixtures.py`, merge `eval/hosting_rules.json`
   into `firebase.json` if redirects/headers changed, deploy.
3. `fvm dart run eval/run_eval.dart --crawl-only --only=<id>` and read
   `eval/results/crawl/<id>.txt` — that is what the model will see.
4. Full run; commit `eval/results/latest.*` with the change that motivated
   the case.
