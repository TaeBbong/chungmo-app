/// Link-parser accuracy evaluation against the hosted fixtures.
///
/// Reproduces the app's link pipeline outside Flutter: the same crawler
/// (`lib/core/utils/crawler.dart`), the same prompt and JSON schema
/// (`lib/data/sources/remote/invitation_prompt.dart`), the same model —
/// only the transport differs (Gemini REST with an API key instead of
/// Firebase AI Logic, which needs App Check and a device).
///
/// Usage (from the repository root, with the fvm-pinned SDK):
///
///   export GEMINI_API_KEY=...
///   fvm dart run eval/run_eval.dart [options]
///
/// Options:
///   --only=id1,id2      run a subset of cases
///   --tag=csr           run cases carrying a tag
///   --difficulty=hard   run cases of one difficulty
///   --model=NAME        Gemini model (default: the app's Constants.geminiModel)
///   --concurrency=N     parallel cases (default 3)
///   --crawl-only        skip the model; only save what the crawler extracts
///   --base-url=URL      override the dataset's base URL (e.g. the emulator)
///   --out=DIR           results directory (default eval/results)
///   --label=TEXT        free-form label stored in the report (e.g. a commit)
///   --rescore=FILE      re-score the predictions saved in a previous report
///                       (no crawling, no model calls) — for scorer changes
library;

import 'dart:convert';
import 'dart:io';

import 'package:chungmo/core/utils/constants.dart';
import 'package:chungmo/core/utils/crawler.dart';
import 'package:chungmo/data/sources/remote/invitation_prompt.dart';
import 'package:http/http.dart' as http;

import 'scoring.dart';

Future<void> main(List<String> args) async {
  final opts = _parseArgs(args);
  final dataset = jsonDecode(File('eval/dataset.json').readAsStringSync())
      as Map<String, dynamic>;
  final datasetBase = dataset['baseUrl'] as String;
  final baseUrl = opts['base-url'] ?? datasetBase;
  final model = opts['model'] ?? Constants.geminiModel;
  final crawlOnly = opts.containsKey('crawl-only');
  final concurrency = int.parse(opts['concurrency'] ?? '3');
  final outDir = Directory(opts['out'] ?? 'eval/results');

  final rescore = opts['rescore'];
  final Map<String, Map<String, dynamic>> saved = rescore == null
      ? const {}
      : {
          for (final r in (jsonDecode(File(rescore).readAsStringSync())
              as Map<String, dynamic>)['cases'] as List)
            (r as Map<String, dynamic>)['id'] as String: r
        };

  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (!crawlOnly && rescore == null && (apiKey == null || apiKey.isEmpty)) {
    stderr.writeln(
        'GEMINI_API_KEY is not set (use --crawl-only to skip the model).');
    exit(2);
  }

  var cases = (dataset['cases'] as List).cast<Map<String, dynamic>>();
  if (opts['only'] != null) {
    final ids = opts['only']!.split(',').toSet();
    cases = cases.where((c) => ids.contains(c['id'])).toList();
  }
  if (opts['tag'] != null) {
    cases =
        cases.where((c) => (c['tags'] as List).contains(opts['tag'])).toList();
  }
  if (opts['difficulty'] != null) {
    cases = cases.where((c) => c['difficulty'] == opts['difficulty']).toList();
  }
  if (cases.isEmpty) {
    stderr.writeln('No cases selected.');
    exit(2);
  }

  if (!crawlOnly && rescore == null) {
    await _preflight(model: model, apiKey: apiKey!);
  }

  final crawlDir = Directory('${outDir.path}/crawl')
    ..createSync(recursive: true);
  final startedAt = DateTime.now();
  stdout.writeln(
      'Running ${cases.length} cases against $baseUrl with $model (concurrency $concurrency)');

  final results = <Map<String, dynamic>>[];
  final queue = List.of(cases);
  Future<void> worker() async {
    while (queue.isNotEmpty) {
      final c = queue.removeAt(0);
      final r = rescore != null
          ? _rescoreCase(c, saved[c['id']], crawlDir: crawlDir)
          : await _runCase(c,
              baseUrl: baseUrl,
              datasetBase: datasetBase,
              model: model,
              apiKey: apiKey,
              crawlOnly: crawlOnly,
              crawlDir: crawlDir);
      results.add(r);
      final score = r['score'] as Map<String, Object?>?;
      final mark = score == null
          ? (r['error'] != null ? 'ERR ' : 'crawl')
          : (score['core'] == true ? 'PASS' : 'FAIL');
      final coverage = r['coverage'] as Map<String, bool>?;
      stdout.writeln(
          '  [$mark] ${c['id']} (${r['crawlChars']} chars, ${r['crawlMs']}+${r['modelMs'] ?? 0} ms)'
          '${score == null ? '' : ' ${_flags(score)}'}'
          '${coverage == null ? '' : ' coverage ${_coverageFlags(coverage)}'}'
          '${r['error'] != null ? ' ${r['error']}' : ''}');
    }
  }

  await Future.wait(List.generate(concurrency, (_) => worker()));
  results.sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));

  final report = {
    'label': opts['label'] ??
        (rescore == null
            ? null
            : 'rescored from ${saved.values.firstOrNull?['label'] ?? rescore}'),
    'rescoredFrom': rescore,
    'startedAt': startedAt.toIso8601String(),
    'durationMs': DateTime.now().difference(startedAt).inMilliseconds,
    'model': model,
    'baseUrl': baseUrl,
    'crawlOnly': crawlOnly,
    'datasetVersion': dataset['version'],
    'caseCount': results.length,
    'summary': crawlOnly ? null : _summarize(results),
    'coverage': _summarizeCoverage(results),
    'cases': results,
  };
  final stamp = startedAt
      .toIso8601String()
      .replaceAll(RegExp(r'[:.]'), '-')
      .substring(0, 19);
  Directory('${outDir.path}/history').createSync(recursive: true);
  final json = const JsonEncoder.withIndent('  ').convert(report);
  File('${outDir.path}/history/$stamp.json').writeAsStringSync(json);
  if (!crawlOnly && cases.length == (dataset['cases'] as List).length) {
    // Only a full run may become the reference result.
    File('${outDir.path}/latest.json').writeAsStringSync(json);
    File('${outDir.path}/latest.md').writeAsStringSync(_markdown(report));
    stdout.writeln('\nWrote ${outDir.path}/latest.json and latest.md');
  } else {
    stdout.writeln(
        '\nWrote ${outDir.path}/history/$stamp.json (partial or crawl-only run; latest.* untouched)');
  }
  if (!crawlOnly) {
    stdout.writeln(
        _summaryLines(report['summary'] as Map<String, dynamic>).join('\n'));
  }
  stdout.writeln(
      _coverageLines(report['coverage'] as Map<String, dynamic>).join('\n'));
}

Future<Map<String, dynamic>> _runCase(
  Map<String, dynamic> c, {
  required String baseUrl,
  required String datasetBase,
  required String model,
  required String? apiKey,
  required bool crawlOnly,
  required Directory crawlDir,
}) async {
  final url = (c['url'] as String).replaceFirst(datasetBase, baseUrl);
  final result = <String, dynamic>{
    'id': c['id'],
    'url': url,
    'template': c['template'],
    'difficulty': c['difficulty'],
    'tags': c['tags'],
  };
  final sw = Stopwatch()..start();
  String? parsed;
  try {
    parsed = await extractContentWithImages(url);
  } catch (e) {
    result['error'] = 'crawl: $e';
  }
  result['crawlMs'] = sw.elapsedMilliseconds;
  result['crawlChars'] = parsed?.length ?? 0;
  File('${crawlDir.path}/${c['id']}.txt').writeAsStringSync(parsed ?? '');
  result['coverage'] =
      crawlCoverage(c['expected'] as Map<String, dynamic>, parsed);
  if (crawlOnly || result['error'] != null) return result;

  sw.reset();
  Map<String, dynamic>? predicted;
  try {
    final raw = await _generate(linkExtractionPrompt(parsed),
        model: model, apiKey: apiKey!, result: result);
    predicted = jsonDecode(raw) as Map<String, dynamic>;
  } catch (e) {
    result['error'] = 'model: $e';
  }
  result['modelMs'] = sw.elapsedMilliseconds;
  result['predicted'] = predicted;
  // A failed call scores as an all-empty prediction so the aggregate rates
  // include it — the user would have seen a failure either way.
  result['score'] = scoreCase(c['expected'] as Map<String, dynamic>, predicted,
          pageUrl: Uri.parse(url))
      .toJson();
  return result;
}

/// Fails fast on a bad key or model name, before any case runs — an
/// all-error run must never become the reference `latest.*` result.
Future<void> _preflight({required String model, required String apiKey}) async {
  final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model');
  final res = await http.get(uri,
      headers: {'x-goog-api-key': apiKey}).timeout(const Duration(seconds: 30));
  if (res.statusCode != 200) {
    stderr.writeln(
        'Preflight failed (HTTP ${res.statusCode}) for model $model: ${res.body.substring(0, res.body.length.clamp(0, 300))}');
    exit(2);
  }
}

/// Applies the current scorer to a prediction saved by an earlier run; the
/// crawl text (for coverage) comes from `results/crawl/<id>.txt` if present.
Map<String, dynamic> _rescoreCase(
    Map<String, dynamic> c, Map<String, dynamic>? saved,
    {required Directory crawlDir}) {
  final crawlFile = File('${crawlDir.path}/${c['id']}.txt');
  final crawled = crawlFile.existsSync() ? crawlFile.readAsStringSync() : null;
  final url = saved?['url'] as String? ?? c['url'] as String;
  final predicted = saved?['predicted'] as Map<String, dynamic>?;
  return {
    'id': c['id'],
    'url': url,
    'template': c['template'],
    'difficulty': c['difficulty'],
    'tags': c['tags'],
    'crawlMs': saved?['crawlMs'] ?? 0,
    'crawlChars': saved?['crawlChars'] ?? crawled?.length ?? 0,
    'modelMs': saved?['modelMs'],
    'promptTokens': saved?['promptTokens'],
    'outputTokens': saved?['outputTokens'],
    if (saved?['error'] != null) 'error': saved!['error'],
    'coverage': crawlCoverage(c['expected'] as Map<String, dynamic>, crawled),
    'predicted': predicted,
    'score': scoreCase(c['expected'] as Map<String, dynamic>, predicted,
            pageUrl: Uri.parse(url))
        .toJson(),
  };
}

/// Gemini REST `generateContent` with the app's schema; retries on 429/5xx.
Future<String> _generate(String prompt,
    {required String model,
    required String apiKey,
    required Map<String, dynamic> result}) async {
  final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent');
  final body = jsonEncode({
    'contents': [
      {
        'role': 'user',
        'parts': [
          {'text': prompt}
        ]
      }
    ],
    'generationConfig': {
      'responseMimeType': 'application/json',
      'responseJsonSchema': scheduleResponseJsonSchema,
    },
  });
  Object? lastError;
  for (var attempt = 0; attempt < 5; attempt++) {
    if (attempt > 0) await Future.delayed(Duration(seconds: 2 << attempt));
    try {
      final res = await http
          .post(uri,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': apiKey
              },
              body: body)
          .timeout(const Duration(seconds: 90));
      if (res.statusCode == 429 || res.statusCode >= 500) {
        lastError = 'HTTP ${res.statusCode}';
        continue;
      }
      if (res.statusCode != 200) {
        throw Exception(
            'HTTP ${res.statusCode}: ${res.body.substring(0, res.body.length.clamp(0, 300))}');
      }
      final json =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final usage = json['usageMetadata'] as Map<String, dynamic>?;
      if (usage != null) {
        result['promptTokens'] = usage['promptTokenCount'];
        result['outputTokens'] = usage['candidatesTokenCount'];
      }
      final candidates = json['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('no candidates: ${json['promptFeedback']}');
      }
      final parts =
          ((candidates.first as Map)['content'] as Map)['parts'] as List;
      return parts.map((p) => (p as Map)['text'] as String? ?? '').join();
    } on Exception catch (e) {
      if (e.toString().contains('HTTP 4')) rethrow;
      lastError = e;
    }
  }
  throw Exception('gave up after retries: $lastError');
}

Map<String, dynamic> _summarize(List<Map<String, dynamic>> results) {
  final scored = results.where((r) => r['score'] != null).toList();
  Map<String, dynamic> rates(List<Map<String, dynamic>> rs) {
    if (rs.isEmpty) return {'count': 0};
    double rate(String f) =>
        rs.where((r) => (r['score'] as Map)[f] == true).length / rs.length;
    return {
      'count': rs.length,
      'core': rate('core'),
      'groom': rate('groom'),
      'bride': rate('bride'),
      'datetime': rate('datetime'),
      'location': rate('location'),
      'accounts': rate('accounts'),
      'thumbnail': rate('thumbnail'),
      'groomLenient': rate('groomLenient'),
      'brideLenient': rate('brideLenient'),
      'accountPrecision': rs
              .map((r) => (r['score'] as Map)['accountPrecision'] as double)
              .reduce((a, b) => a + b) /
          rs.length,
      'accountRecall': rs
              .map((r) => (r['score'] as Map)['accountRecall'] as double)
              .reduce((a, b) => a + b) /
          rs.length,
    };
  }

  Map<String, dynamic> groupBy(String Function(Map<String, dynamic>) key) {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final r in scored) {
      groups.putIfAbsent(key(r), () => []).add(r);
    }
    return {for (final k in groups.keys.toList()..sort()) k: rates(groups[k]!)};
  }

  final byTag = <String, List<Map<String, dynamic>>>{};
  for (final r in scored) {
    for (final t in r['tags'] as List) {
      byTag.putIfAbsent(t as String, () => []).add(r);
    }
  }
  final crawlMs = results.map((r) => r['crawlMs'] as int).toList();
  final modelMs = results
      .where((r) => r['modelMs'] != null)
      .map((r) => r['modelMs'] as int)
      .toList();
  return {
    'overall': rates(scored),
    'errors': results.where((r) => r['error'] != null).length,
    'byDifficulty': groupBy((r) => r['difficulty'] as String),
    'byTemplate': groupBy((r) => r['template'] as String),
    'byTag': {for (final k in byTag.keys.toList()..sort()) k: rates(byTag[k]!)},
    'meanCrawlMs':
        crawlMs.isEmpty ? 0 : crawlMs.reduce((a, b) => a + b) ~/ crawlMs.length,
    'meanModelMs':
        modelMs.isEmpty ? 0 : modelMs.reduce((a, b) => a + b) ~/ modelMs.length,
    'promptTokens':
        results.fold<int>(0, (s, r) => s + ((r['promptTokens'] as int?) ?? 0)),
  };
}

/// Share of cases whose crawled text contains each expected value, overall
/// and per template — the ceiling any model could reach on that group.
Map<String, dynamic> _summarizeCoverage(List<Map<String, dynamic>> results) {
  final covered = results.where((r) => r['coverage'] != null).toList();
  Map<String, dynamic> rates(List<Map<String, dynamic>> rs) {
    if (rs.isEmpty) return {'count': 0};
    double rate(String f) =>
        rs.where((r) => (r['coverage'] as Map)[f] == true).length / rs.length;
    return {
      'count': rs.length,
      'all': rs
              .where(
                  (r) => (r['coverage'] as Map).values.every((v) => v == true))
              .length /
          rs.length,
      for (final f in ['groom', 'bride', 'date', 'location', 'accounts'])
        f: rate(f),
    };
  }

  final byTemplate = <String, List<Map<String, dynamic>>>{};
  for (final r in covered) {
    byTemplate.putIfAbsent(r['template'] as String, () => []).add(r);
  }
  return {
    'overall': rates(covered),
    'byTemplate': {
      for (final k in byTemplate.keys.toList()..sort()) k: rates(byTemplate[k]!)
    },
  };
}

String _coverageFlags(Map<String, bool> c) => [
      'g${c['groom'] == true ? '✓' : '✗'}',
      'b${c['bride'] == true ? '✓' : '✗'}',
      'd${c['date'] == true ? '✓' : '✗'}',
      'l${c['location'] == true ? '✓' : '✗'}',
      'a${c['accounts'] == true ? '✓' : '✗'}',
    ].join(' ');

List<String> _coverageLines(Map<String, dynamic> cov) {
  final o = cov['overall'] as Map<String, dynamic>;
  return [
    'Crawl coverage (${o['count']} cases): all ${_pct(o['all'])} · groom ${_pct(o['groom'])} · bride ${_pct(o['bride'])} · date ${_pct(o['date'])} · location ${_pct(o['location'])} · accounts ${_pct(o['accounts'])}',
    for (final e in (cov['byTemplate'] as Map<String, dynamic>).entries)
      '  ${e.key}: all ${_pct((e.value as Map)['all'])} (${(e.value as Map)['count']})',
  ];
}

String _pct(Object? v) => v is num ? '${(v * 100).round()}%' : '-';

String _flags(Map<String, Object?> s) => [
      'G${s['groom'] == true ? '✓' : '✗'}',
      'B${s['bride'] == true ? '✓' : '✗'}',
      'D${s['datetime'] == true ? '✓' : '✗'}',
      'L${s['location'] == true ? '✓' : '✗'}',
      'A${s['accounts'] == true ? '✓' : '✗'}',
      'T${s['thumbnail'] == true ? '✓' : '✗'}',
    ].join(' ');

List<String> _summaryLines(Map<String, dynamic> s) {
  final o = s['overall'] as Map<String, dynamic>;
  return [
    'Overall (${o['count']} cases): core ${_pct(o['core'])} · groom ${_pct(o['groom'])} · bride ${_pct(o['bride'])} · datetime ${_pct(o['datetime'])} · location ${_pct(o['location'])} · accounts ${_pct(o['accounts'])} · thumbnail ${_pct(o['thumbnail'])}',
    for (final e in (s['byDifficulty'] as Map<String, dynamic>).entries)
      '  ${e.key}: core ${_pct((e.value as Map)['core'])} (${(e.value as Map)['count']})',
  ];
}

String _markdown(Map<String, dynamic> report) {
  final s = report['summary'] as Map<String, dynamic>;
  final o = s['overall'] as Map<String, dynamic>;
  final b = StringBuffer()
    ..writeln('# Link parser eval — ${report['model']}')
    ..writeln()
    ..writeln(
        '- Run: ${report['startedAt']}${report['label'] != null ? ' (${report['label']})' : ''}')
    ..writeln(
        '- Cases: ${report['caseCount']} · errors: ${s['errors']} · mean crawl ${s['meanCrawlMs']} ms · mean model ${s['meanModelMs']} ms · prompt tokens ${s['promptTokens']}')
    ..writeln()
    ..writeln('## Overall')
    ..writeln()
    ..writeln(
        '| core | groom | bride | datetime | location | accounts | thumbnail | groom (lenient) | bride (lenient) | account P / R |')
    ..writeln('|---|---|---|---|---|---|---|---|---|---|')
    ..writeln(
        '| **${_pct(o['core'])}** | ${_pct(o['groom'])} | ${_pct(o['bride'])} | ${_pct(o['datetime'])} | ${_pct(o['location'])} | ${_pct(o['accounts'])} | ${_pct(o['thumbnail'])} | ${_pct(o['groomLenient'])} | ${_pct(o['brideLenient'])} | ${_pct(o['accountPrecision'])} / ${_pct(o['accountRecall'])} |')
    ..writeln()
    ..writeln(
        '`core` = groom, bride, datetime, location and the full account set all correct — the schedule saves without manual fixes.')
    ..writeln();
  void table(String title, Map<String, dynamic> groups) {
    b
      ..writeln('## $title')
      ..writeln()
      ..writeln(
          '| group | n | core | groom | bride | datetime | location | accounts | thumbnail |')
      ..writeln('|---|---|---|---|---|---|---|---|---|');
    for (final e in groups.entries) {
      final g = e.value as Map<String, dynamic>;
      b.writeln(
          '| ${e.key} | ${g['count']} | ${_pct(g['core'])} | ${_pct(g['groom'])} | ${_pct(g['bride'])} | ${_pct(g['datetime'])} | ${_pct(g['location'])} | ${_pct(g['accounts'])} | ${_pct(g['thumbnail'])} |');
    }
    b.writeln();
  }

  final cov = report['coverage'] as Map<String, dynamic>;
  final co = cov['overall'] as Map<String, dynamic>;
  b
    ..writeln('## Crawl coverage (model-independent ceiling)')
    ..writeln()
    ..writeln(
        'Whether the crawler\'s text contains each expected value verbatim; a field missing here is unreachable for any prompt or model.')
    ..writeln()
    ..writeln(
        '| group | n | all | groom | bride | date | location | accounts |')
    ..writeln('|---|---|---|---|---|---|---|---|')
    ..writeln(
        '| overall | ${co['count']} | **${_pct(co['all'])}** | ${_pct(co['groom'])} | ${_pct(co['bride'])} | ${_pct(co['date'])} | ${_pct(co['location'])} | ${_pct(co['accounts'])} |');
  for (final e in (cov['byTemplate'] as Map<String, dynamic>).entries) {
    final g = e.value as Map<String, dynamic>;
    b.writeln(
        '| ${e.key} | ${g['count']} | ${_pct(g['all'])} | ${_pct(g['groom'])} | ${_pct(g['bride'])} | ${_pct(g['date'])} | ${_pct(g['location'])} | ${_pct(g['accounts'])} |');
  }
  b.writeln();

  table('By difficulty', s['byDifficulty'] as Map<String, dynamic>);
  table('By template', s['byTemplate'] as Map<String, dynamic>);
  table('By tag', s['byTag'] as Map<String, dynamic>);

  b
    ..writeln('## Cases')
    ..writeln()
    ..writeln(
        '| id | template | difficulty | G | B | D | L | A | T | chars | ms | mismatches |')
    ..writeln('|---|---|---|---|---|---|---|---|---|---|---|---|');
  for (final r in report['cases'] as List) {
    final sc = r['score'] as Map<String, dynamic>?;
    String m(String f) => sc == null ? '·' : (sc[f] == true ? '✓' : '✗');
    final mism = sc == null
        ? (r['error'] ?? '')
        : (sc['mismatches'] as Map)
            .entries
            .map((e) => '${e.key}: ${e.value}')
            .join('; ');
    b.writeln(
        '| ${r['id']} | ${r['template']} | ${r['difficulty']} | ${m('groom')} | ${m('bride')} | ${m('datetime')} | ${m('location')} | ${m('accounts')} | ${m('thumbnail')} | ${r['crawlChars']} | ${r['crawlMs']}+${r['modelMs'] ?? 0} | ${mism.toString().replaceAll('|', '\\|')} |');
  }
  return b.toString();
}

Map<String, String> _parseArgs(List<String> args) {
  final opts = <String, String>{};
  for (final a in args) {
    if (!a.startsWith('--')) {
      stderr.writeln('Unknown argument: $a');
      exit(2);
    }
    final eq = a.indexOf('=');
    if (eq == -1) {
      opts[a.substring(2)] = '';
    } else {
      opts[a.substring(2, eq)] = a.substring(eq + 1);
    }
  }
  return opts;
}
