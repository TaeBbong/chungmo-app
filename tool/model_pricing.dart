/// Pure logic behind `tool/model_catalog.dart`: reading Gemini prices out of
/// the Cloud Billing Catalog, and deciding which model is cheaper.
///
/// Kept apart from the network code so the fragile part — matching the
/// price list's wording to model ids — is tested without credentials.
library;

/// A model's standard on-demand text price, per million tokens.
class ModelPrice {
  final double input;
  final double output;

  const ModelPrice(this.input, this.output);

  /// Cheaper or equal on both prices and strictly cheaper on one.
  ///
  /// The only order that needs no weighting: a parse's mix of input and
  /// output tokens has not been measured (thinking tokens bill as output),
  /// so a model cheaper on one side and dearer on the other is reported as
  /// a trade-off for a person to judge, not ranked.
  bool dominates(ModelPrice other) =>
      input <= other.input &&
      output <= other.output &&
      (input < other.input || output < other.output);

  @override
  String toString() => 'ModelPrice($input, $output)';
}

/// How a candidate's price compares with the configured model's.
enum PriceVerdict {
  /// Cheaper or equal on both sides, strictly cheaper on one.
  cheaper,

  /// The same on both sides.
  same,

  /// Dearer or equal on both sides.
  dearer,

  /// Cheaper on one side, dearer on the other: a person decides.
  tradeOff,

  /// The candidate has no price, so it cannot be ranked at all — which is
  /// not the same as not cheaper.
  unpriced,
}

/// Compares [candidate] with [current]; null when [current] has no price.
PriceVerdict? comparePrice(ModelPrice? candidate, ModelPrice? current) {
  if (current == null) return null;
  if (candidate == null) return PriceVerdict.unpriced;
  if (candidate.dominates(current)) return PriceVerdict.cheaper;
  if (current.dominates(candidate)) return PriceVerdict.dearer;
  if (candidate.input == current.input && candidate.output == current.output) {
    return PriceVerdict.same;
  }
  return PriceVerdict.tradeOff;
}

/// Stable general-purpose text models, e.g. `gemini-3.5-flash-lite`.
///
/// Google names a stable release by version and tier alone; previews,
/// experiments, TTS, image and task-specific models all carry a suffix or a
/// codename. Matching the stable shape is narrower than any deny-list of
/// suffixes, which a new model family would slip past.
final RegExp stableTextModel =
    RegExp(r'^gemini-\d+(\.\d+)?-(flash|flash-lite|pro)$');

/// `Generate content input token count gemini 2.5 flash short input text`
final RegExp _textSku = RegExp(
    r'^generate content (input|output) token count (gemini[\w. -]*?) text$',
    caseSensitive: false);

/// Price-list variants billed by prompt length: the short one is the
/// price a parse pays, since invitation prompts stay well inside it.
final RegExp _lengthVariant = RegExp(r'-(short|long)-(input|output)$');

/// Reads standard text prices from Billing Catalog SKUs, keyed by model id.
///
/// [skus] is the `skus` array of `services/AEFD-7695-64FA/skus`. Flex,
/// priority, batch, cached and non-text SKUs are ignored: the app uses the
/// standard tier. A model listed by length variant (`gemini-2.5-flash` as
/// `...-short-input` / `...-long-input`) is read at its short price.
Map<String, ModelPrice> parsePrices(List<Map<String, dynamic>> skus) {
  // Per model and side, the price from the most specific SKU seen so far:
  // rank 0 is an unsplit price, 1 the short-prompt one, 2 the long-prompt.
  final Map<String, Map<String, (int, double)>> best = {};
  for (final Map<String, dynamic> sku in skus) {
    final RegExpMatch? match =
        _textSku.firstMatch((sku['description'] as String? ?? '').trim());
    if (match == null) continue;
    final double? perMillion = _perMillion(sku);
    if (perMillion == null) continue;
    final String side = match.group(1)!.toLowerCase();
    final String slug =
        match.group(2)!.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    final RegExpMatch? variant = _lengthVariant.firstMatch(slug);
    final String model =
        variant == null ? slug : slug.substring(0, variant.start);
    final int rank = switch (variant?.group(1)) {
      null => 0,
      'short' => 1,
      _ => 2,
    };
    final Map<String, (int, double)> prices = best.putIfAbsent(model, () => {});
    final (int, double)? current = prices[side];
    if (current == null || rank < current.$1) prices[side] = (rank, perMillion);
  }
  return {
    for (final MapEntry<String, Map<String, (int, double)>> entry
        in best.entries)
      if (entry.value['input'] case (_, final double input)?)
        if (entry.value['output'] case (_, final double output)?)
          entry.key: ModelPrice(input, output),
  };
}

/// The SKU's price per million tokens, or null when it is not per token.
///
/// `unitPrice` is the price of one `usageUnit` (one token, "count");
/// `displayQuantity` only says how the console prints it. The highest tier
/// is used — it is the steady-state rate past any free allowance.
double? _perMillion(Map<String, dynamic> sku) {
  final List<dynamic> pricing = sku['pricingInfo'] as List? ?? const [];
  if (pricing.isEmpty) return null;
  final Map<String, dynamic> expression = (pricing.first
      as Map<String, dynamic>)['pricingExpression'] as Map<String, dynamic>;
  if (expression['usageUnit'] != 'count') return null;
  final List<dynamic> tiers = expression['tieredRates'] as List? ?? const [];
  if (tiers.isEmpty) return null;
  final Map<String, dynamic> unit =
      (tiers.last as Map<String, dynamic>)['unitPrice'] as Map<String, dynamic>;
  final double perToken = int.parse('${unit['units'] ?? '0'}') +
      ((unit['nanos'] as num?) ?? 0) / 1e9;
  return perToken * 1000000;
}
