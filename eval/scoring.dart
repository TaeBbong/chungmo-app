/// Field-level scoring for the link-parser evaluation.
///
/// Pure functions over the dataset's `expected` object and the model's
/// parsed JSON, so they can be unit-tested without network access
/// (`test/eval/scoring_test.dart`).
library;

/// Result of scoring one case; every flag is `true` when that field matched.
class CaseScore {
  final bool groom;
  final bool bride;
  final bool datetime;
  final bool location;
  final bool accounts;
  final bool thumbnail;

  /// Account precision/recall over `side|bank|number` keys, 1.0 when both
  /// sides are empty and the prediction is empty too.
  final double accountPrecision;
  final double accountRecall;

  /// Lenient name matches: one name contains the other (e.g. given name
  /// only). Reported next to the exact rates, never counted as correct.
  final bool groomLenient;
  final bool brideLenient;

  /// Why a field failed, keyed by field name — feeds the Markdown report.
  final Map<String, String> mismatches;

  const CaseScore({
    required this.groom,
    required this.bride,
    required this.datetime,
    required this.location,
    required this.accounts,
    required this.thumbnail,
    required this.accountPrecision,
    required this.accountRecall,
    required this.groomLenient,
    required this.brideLenient,
    required this.mismatches,
  });

  /// The app-facing notion of "parsed correctly": every field the user
  /// would otherwise have to fix by hand. The thumbnail is cosmetic.
  bool get core => groom && bride && datetime && location && accounts;

  Map<String, Object?> toJson() => {
        'groom': groom,
        'bride': bride,
        'datetime': datetime,
        'location': location,
        'accounts': accounts,
        'thumbnail': thumbnail,
        'core': core,
        'accountPrecision': accountPrecision,
        'accountRecall': accountRecall,
        'groomLenient': groomLenient,
        'brideLenient': brideLenient,
        'mismatches': mismatches,
      };
}

/// Scores [predicted] (the model's JSON, or `null` when the call failed)
/// against the dataset's [expected] block. [pageUrl] resolves relative
/// thumbnail URLs the way a browser would.
CaseScore scoreCase(
    Map<String, dynamic> expected, Map<String, dynamic>? predicted,
    {required Uri pageUrl}) {
  final mismatches = <String, String>{};
  final p = predicted ?? const <String, dynamic>{};

  final expGroom = expected['groom'] as String;
  final expBride = expected['bride'] as String;
  final predGroom = _str(p['groom']);
  final predBride = _str(p['bride']);
  final groom = nameMatches(expGroom, expected['groomAliases'], predGroom);
  final bride = nameMatches(expBride, expected['brideAliases'], predBride);
  if (!groom) mismatches['groom'] = 'expected "$expGroom", got "$predGroom"';
  if (!bride) mismatches['bride'] = 'expected "$expBride", got "$predBride"';

  final expDate = expected['datetime'] as String?;
  final predDate = _str(p['datetime']);
  final datetime = datetimeMatches(expDate, predDate);
  if (!datetime) {
    mismatches['datetime'] = 'expected "${expDate ?? 'null'}", got "$predDate"';
  }

  final keywords = (expected['locationKeywords'] as List).cast<String>();
  final predLocation = _str(p['location']);
  final location = locationMatches(keywords, predLocation);
  if (!location) {
    mismatches['location'] = 'expected keywords $keywords, got "$predLocation"';
  }

  final expKeys = <String>{
    ...accountKeys('groom', expected['groomAccounts'] as List?),
    ...accountKeys('bride', expected['brideAccounts'] as List?),
  };
  final predKeys = <String>{
    ...accountKeys('groom', p['groomAccounts'] as List?),
    ...accountKeys('bride', p['brideAccounts'] as List?),
  };
  final hit = expKeys.intersection(predKeys).length;
  final precision =
      predKeys.isEmpty ? (expKeys.isEmpty ? 1.0 : 0.0) : hit / predKeys.length;
  final recall =
      expKeys.isEmpty ? (predKeys.isEmpty ? 1.0 : 0.0) : hit / expKeys.length;
  final accounts = expKeys.length == predKeys.length && hit == expKeys.length;
  if (!accounts) {
    mismatches['accounts'] =
        'missing ${expKeys.difference(predKeys).toList()}, extra ${predKeys.difference(expKeys).toList()}';
  }

  final thumbs = (expected['thumbnails'] as List).cast<String>().toSet();
  final predThumb = _str(p['thumbnail']);
  final thumbnail = predThumb.isNotEmpty &&
      thumbs.contains(pageUrl.resolve(predThumb).toString());
  if (!thumbnail) {
    mismatches['thumbnail'] = 'expected one of $thumbs, got "$predThumb"';
  }

  return CaseScore(
    groom: groom,
    bride: bride,
    datetime: datetime,
    location: location,
    accounts: accounts,
    thumbnail: thumbnail,
    accountPrecision: precision,
    accountRecall: recall,
    groomLenient: groom || nameLenient(expGroom, predGroom),
    brideLenient: bride || nameLenient(expBride, predBride),
    mismatches: mismatches,
  );
}

String _str(Object? v) => v == null ? '' : v.toString().trim();

/// Strips whitespace and common decorations ("신랑 김민준", "김민준 (신랑)").
String normalizeName(String s) => s
    .replaceAll(RegExp(r'\(.*?\)'), '')
    .replaceAll(
        RegExp(r'^(신랑|신부|groom|bride)\s*[:：]?\s*', caseSensitive: false), '')
    .replaceAll(RegExp(r'[\s·.,]'), '')
    .toLowerCase();

/// Exact match against the expected name or any of its aliases (an
/// English page may print "Minjun Kim" for 김민준).
bool nameMatches(String expected, Object? aliases, String predicted) {
  final p = normalizeName(predicted);
  if (p.isEmpty) return false;
  return [expected, ...?(aliases as List?)?.cast<String>()]
      .any((n) => normalizeName(n) == p);
}

/// True when one normalized name contains the other, both at least two
/// characters long (given name vs full name).
bool nameLenient(String expected, String predicted) {
  final a = normalizeName(expected), b = normalizeName(predicted);
  if (a.length < 2 || b.length < 2) return false;
  return a.contains(b) || b.contains(a);
}

/// Instant equality at minute precision. A predicted value without a UTC
/// offset is read as KST, the only timezone these invitations use.
bool datetimeMatches(String? expected, String predicted) {
  if (expected == null) return predicted.isEmpty || predicted == 'null';
  final exp = DateTime.tryParse(expected);
  final pred = parseKst(predicted);
  if (exp == null || pred == null) return false;
  return exp.toUtc().difference(pred.toUtc()).inMinutes == 0;
}

/// Parses an ISO 8601 string, assuming +09:00 when no offset is given.
DateTime? parseKst(String s) {
  if (s.isEmpty) return null;
  final hasOffset = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(s);
  final normalized = hasOffset ? s : '${s.replaceAll(' ', 'T')}+09:00';
  return DateTime.tryParse(normalized);
}

/// Every keyword must appear in the prediction, ignoring whitespace.
bool locationMatches(List<String> keywords, String predicted) {
  final hay = predicted.replaceAll(RegExp(r'\s'), '').toLowerCase();
  if (hay.isEmpty) return false;
  return keywords.every(
      (k) => hay.contains(k.replaceAll(RegExp(r'\s'), '').toLowerCase()));
}

const _bankAliases = <String, String>{
  'kb국민': '국민',
  'kb': '국민',
  'nh농협': '농협',
  'nh': '농협',
  '농협중앙회': '농협',
  'ibk기업': '기업',
  'ibk': '기업',
  '카뱅': '카카오뱅크',
  '카카오': '카카오뱅크',
  '토스': '토스뱅크',
  'k뱅크': '케이뱅크',
  'sc': 'sc제일',
  '스탠다드차타드': 'sc제일',
  '우체국예금': '우체국',
  'mg새마을금고': '새마을금고',
  'mg': '새마을금고',
};

/// Canonical bank token: lower-cased, no spaces, no trailing "은행",
/// common brand prefixes folded.
String normalizeBank(String bank) {
  var b = bank.replaceAll(RegExp(r'\s'), '').toLowerCase();
  b = b.replaceAll(RegExp(r'은행$'), '');
  return _bankAliases[b] ?? b;
}

/// Digits only, so "123-45-6789" and "123 45 6789" and "123456789" agree.
String normalizeAccountNumber(String number) =>
    number.replaceAll(RegExp(r'\D'), '');

/// `side|bank|number` keys for one side's account list.
Set<String> accountKeys(String side, List? accounts) {
  final keys = <String>{};
  for (final a in accounts ?? const []) {
    if (a is! Map) continue;
    final number = normalizeAccountNumber(_str(a['number']));
    if (number.isEmpty) continue;
    keys.add('$side|${normalizeBank(_str(a['bank']))}|$number');
  }
  return keys;
}

/// Model-independent upper bound: whether each expected value is present
/// verbatim (ignoring whitespace) in the crawler's output. A field the
/// crawler never surfaced cannot be extracted by any prompt or model.
Map<String, bool> crawlCoverage(
    Map<String, dynamic> expected, String? crawled) {
  final hay = (crawled ?? '').replaceAll(RegExp(r'\s'), '').toLowerCase();
  bool has(String s) =>
      s.isNotEmpty &&
      hay.contains(s.replaceAll(RegExp(r'\s'), '').toLowerCase());
  final dateText = expected['dateText'] as String? ?? '';
  final numbers = [
    ...(expected['groomAccounts'] as List? ?? const []),
    ...(expected['brideAccounts'] as List? ?? const []),
  ].map((a) => normalizeAccountNumber((a as Map)['number'] as String));
  final digitsHay = hay.replaceAll(RegExp(r'[\-\s]'), '');
  return {
    'groom': has(expected['groom'] as String),
    'bride': has(expected['bride'] as String),
    // A no-date invitation is covered by definition.
    'date': dateText.isEmpty || has(dateText),
    'location':
        (expected['locationKeywords'] as List).cast<String>().every(has),
    'accounts': numbers.every((n) => digitsHay.contains(n)),
  };
}
