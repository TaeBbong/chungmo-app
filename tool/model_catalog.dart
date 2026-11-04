/// Is the configured Gemini model still served, and still the cheapest?
///
/// The app reads its model from the Remote Config parameter `model_name`
/// (docs/MODEL_SELECTION.md). The policy is the cheapest stable model, but
/// no single source answers that: `models.list` has no prices and lists
/// models that no longer answer (gemini-2.5-flash-lite returned 404 on
/// 2026-10-28 while still listed), and the Cloud Billing Catalog has
/// prices under its own naming. This joins the two and probes each
/// candidate with a one-word request.
///
/// Usage (from the repository root):
///
///   export GEMINI_API_KEY=...        # models.list and the probes
///   gcloud auth login                # the price list and Remote Config
///   fvm dart run tool/model_catalog.dart [options]
///
/// Options:
///   --model=NAME    judge NAME instead of the live `model_name`
///   --no-probe      skip the live requests (prices and listing only)
///
/// Exit codes: 0 the configured model is served and nothing stable is
/// cheaper; 1 it should change (not served, unpriced, or a cheaper model
/// exists); 2 setup failed.
library;

import 'dart:convert';
import 'dart:io';

import 'package:chungmo/core/utils/constants.dart';
import 'package:http/http.dart' as http;

import 'model_pricing.dart';

const String _project = 'chung-mo';

/// The Billing Catalog service named "Gemini API".
const String _geminiService = 'AEFD-7695-64FA';

const String _gemini = 'https://generativelanguage.googleapis.com/v1beta';

Future<void> main(List<String> args) async {
  final String? modelArg = args
      .where((a) => a.startsWith('--model='))
      .map((a) => a.substring('--model='.length))
      .firstOrNull;
  final bool probe = !args.contains('--no-probe');

  final String? apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    stderr.writeln('GEMINI_API_KEY is not set.');
    exit(2);
  }
  final String? token = await _gcloudToken();
  if (token == null) {
    stderr.writeln('No gcloud access token; run `gcloud auth login`.');
    exit(2);
  }

  final (String configured, String source) =
      modelArg != null ? (modelArg, '--model') : await _liveModel(token);
  final Set<String> listed = await _listedModels(apiKey);
  final Map<String, ModelPrice> prices = parsePrices(await _skus(token));

  final List<String> candidates = {
    configured,
    ...listed.where(stableTextModel.hasMatch),
  }.toList()
    ..sort();

  final Map<String, String?> served = {};
  if (probe) {
    for (final String model in [
      ...candidates,
      Constants.geminiSafetyNetModel
    ]) {
      served[model] = await _probe(apiKey, model);
    }
  }

  stdout.writeln('Configured: $configured (from $source)\n');
  stdout.writeln('KRW per 1M tokens, standard tier, Cloud Billing Catalog');
  stdout.writeln('${'model'.padRight(26)} ${'input'.padLeft(9)} '
      '${'output'.padLeft(9)}  ${'served'.padRight(30)} note');

  final ModelPrice? current = prices[configured];
  final List<String> cheaper = [];
  final List<String> unpriced = [];
  for (final String model in candidates) {
    final ModelPrice? price = prices[model];
    final bool live = !probe || served[model] != null;
    final PriceVerdict? verdict =
        model == configured || !live ? null : comparePrice(price, current);
    final String note = model == configured
        ? '<- configured'
        : switch (verdict) {
            PriceVerdict.cheaper => 'CHEAPER',
            PriceVerdict.same => 'same price',
            PriceVerdict.tradeOff => 'trade-off',
            PriceVerdict.unpriced => 'unpriced',
            PriceVerdict.dearer || null => '',
          };
    if (verdict == PriceVerdict.cheaper) cheaper.add(model);
    if (verdict == PriceVerdict.unpriced) unpriced.add(model);
    stdout.writeln('${model.padRight(26)} '
        '${(price?.input.toStringAsFixed(1) ?? '-').padLeft(9)} '
        '${(price?.output.toStringAsFixed(1) ?? '-').padLeft(9)}  '
        '${_servedLabel(probe, served, model).padRight(30)} $note');
  }
  if (probe) {
    stdout.writeln('\nSafety net ${Constants.geminiSafetyNetModel}: '
        '${_servedLabel(probe, served, Constants.geminiSafetyNetModel)}');
  }

  final List<String> problems = [
    if (probe && served[configured] == null)
      '$configured is not served — change model_name now.',
    if (current == null)
      '$configured has no standard text price in the Billing Catalog; '
          'check the SKU wording against tool/model_pricing.dart.',
    for (final String model in cheaper)
      '$model is cheaper on both input and output than $configured.',
    if (!listed.contains(configured))
      '$configured is missing from models.list.',
  ];
  for (final String model in unpriced) {
    // Not a failure: the catalog may list it under another name (on
    // 2026-11-04 only `gemini-3.1-flash-lite-preview` had a price). But it
    // may be cheaper, and only a person can check.
    stdout.writeln('\nNOTE: $model is served but has no standard text price '
        'in the Billing Catalog, so it could not be ranked.');
  }
  if (problems.isEmpty) {
    stdout.writeln('\nOK: $configured is served and nothing stable is '
        'cheaper on both sides.');
    exit(0);
  }
  stdout.writeln('');
  for (final String problem in problems) {
    stdout.writeln('ACTION: $problem');
  }
  exit(1);
}

String _servedLabel(bool probe, Map<String, String?> served, String model) {
  if (!probe) return 'not probed';
  final String? version = served[model];
  if (version == null) return 'NO';
  return version == model ? 'yes' : 'yes -> $version';
}

Future<String?> _gcloudToken() async {
  try {
    final ProcessResult result =
        await Process.run('gcloud', ['auth', 'print-access-token']);
    if (result.exitCode != 0) return null;
    final String token = (result.stdout as String).trim();
    return token.isEmpty ? null : token;
  } on ProcessException {
    return null;
  }
}

/// Headers for a Google API called with the maintainer's own credentials.
///
/// Remote Config needs [quotaProject]; the Billing Catalog is public
/// pricing and must not get one — naming chung-mo there bills the call to
/// a project that has the Cloud Billing API disabled, and it answers 403.
Map<String, String> _googleHeaders(String token, {bool quotaProject = true}) =>
    {
      'Authorization': 'Bearer $token',
      if (quotaProject) 'x-goog-user-project': _project,
    };

/// The published `model_name`, or the in-app default when none is.
Future<(String, String)> _liveModel(String token) async {
  final http.Response response = await http.get(
      Uri.parse('https://firebaseremoteconfig.googleapis.com/v1/projects/'
          '$_project/remoteConfig'),
      headers: _googleHeaders(token));
  if (response.statusCode == 200) {
    final Map<String, dynamic> template =
        jsonDecode(response.body) as Map<String, dynamic>;
    final Object? value = (((template['parameters'] as Map?)?['model_name']
        as Map?)?['defaultValue'] as Map?)?['value'];
    if (value is String && value.trim().isNotEmpty) {
      return (value.trim(), 'Remote Config');
    }
  }
  return (Constants.geminiModel, 'in-app default; no model_name published');
}

Future<Set<String>> _listedModels(String apiKey) async {
  final Set<String> models = {};
  String? pageToken;
  do {
    final http.Response response = await http.get(
        Uri.parse('$_gemini/models').replace(queryParameters: {
          'pageSize': '1000',
          if (pageToken != null) 'pageToken': pageToken,
        }),
        headers: {'x-goog-api-key': apiKey});
    _expectOk(response, 'models.list');
    final Map<String, dynamic> page =
        jsonDecode(response.body) as Map<String, dynamic>;
    for (final Map<String, dynamic> model
        in (page['models'] as List? ?? const []).cast()) {
      final List<dynamic> methods =
          model['supportedGenerationMethods'] as List? ?? const [];
      if (methods.contains('generateContent')) {
        models.add((model['name'] as String).replaceFirst('models/', ''));
      }
    }
    pageToken = page['nextPageToken'] as String?;
  } while (pageToken != null && pageToken.isNotEmpty);
  return models;
}

Future<List<Map<String, dynamic>>> _skus(String token) async {
  final List<Map<String, dynamic>> skus = [];
  String? pageToken;
  do {
    final http.Response response = await http.get(
        Uri.parse('https://cloudbilling.googleapis.com/v1/services/'
                '$_geminiService/skus')
            .replace(queryParameters: {
          'currencyCode': 'KRW',
          'pageSize': '5000',
          if (pageToken != null) 'pageToken': pageToken,
        }),
        headers: _googleHeaders(token, quotaProject: false));
    _expectOk(response, 'the Billing Catalog');
    final Map<String, dynamic> page =
        jsonDecode(response.body) as Map<String, dynamic>;
    skus.addAll((page['skus'] as List? ?? const []).cast());
    pageToken = page['nextPageToken'] as String?;
  } while (pageToken != null && pageToken.isNotEmpty);
  return skus;
}

/// The model version that answered a one-word request, or null when the
/// model did not answer.
///
/// Listing is not enough: a listed model can answer 404. The reply's
/// `modelVersion` also shows what an alias resolves to.
Future<String?> _probe(String apiKey, String model) async {
  final http.Response response = await http.post(
    Uri.parse('$_gemini/models/$model:generateContent'),
    headers: {'x-goog-api-key': apiKey, 'Content-Type': 'application/json'},
    body: jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': 'Reply with the single word: ok'}
          ]
        }
      ],
    }),
  );
  if (response.statusCode != 200) return null;
  final Map<String, dynamic> body =
      jsonDecode(response.body) as Map<String, dynamic>;
  return body['modelVersion'] as String? ?? model;
}

void _expectOk(http.Response response, String what) {
  if (response.statusCode == 200) return;
  stderr.writeln('Reading $what failed: HTTP ${response.statusCode}\n'
      '${response.body}');
  exit(2);
}
