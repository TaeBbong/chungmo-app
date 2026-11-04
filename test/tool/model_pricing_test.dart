/// Reading Gemini prices from the Cloud Billing Catalog, and ranking them.
///
/// The SKU shapes below are copied from the live catalog (service
/// `AEFD-7695-64FA`, 2026-10-28); only the prices are rounded.
library;

import 'package:flutter_test/flutter_test.dart';

import '../../tool/model_pricing.dart';

/// A per-token SKU priced at [perMillion] KRW per million tokens.
Map<String, dynamic> _sku(String description, double perMillion) {
  final double perToken = perMillion / 1000000;
  return {
    'description': description,
    'pricingInfo': [
      {
        'pricingExpression': {
          'usageUnit': 'count',
          'displayQuantity': 1000000,
          'tieredRates': [
            {
              'startUsageAmount': 0,
              'unitPrice': {
                'currencyCode': 'KRW',
                'units': '${perToken.floor()}',
                'nanos': ((perToken - perToken.floor()) * 1e9).round(),
              }
            }
          ],
        }
      }
    ],
  };
}

void main() {
  group('parsePrices', () {
    test('reads the standard text price per million tokens', () {
      final prices = parsePrices([
        _sku('Generate content input token count gemini 3.5 flash lite text',
            407.6),
        _sku('Generate content output token count gemini 3.5 flash lite text',
            3396.9),
      ]);

      expect(prices.keys, ['gemini-3.5-flash-lite']);
      expect(prices['gemini-3.5-flash-lite']!.input, closeTo(407.6, 1e-6));
      expect(prices['gemini-3.5-flash-lite']!.output, closeTo(3396.9, 1e-6));
    });

    test('reads unitPrice per token, not per displayQuantity', () {
      // The live SKU: 679375 nanos per token is 679.375 KRW per million.
      // Dividing by displayQuantity instead reads every model as free —
      // the mistake made the first time these prices were computed.
      final Map<String, dynamic> sku =
          _sku('Generate content input token count gemini 9 flash text', 0);
      final Map<String, dynamic> rate = ((sku['pricingInfo'] as List).first
          as Map)['pricingExpression']['tieredRates'][0]['unitPrice'];
      rate['units'] = '0';
      rate['nanos'] = 679375;

      final prices = parsePrices([
        sku,
        _sku('Generate content output token count gemini 9 flash text', 1),
      ]);

      expect(prices['gemini-9-flash']!.input, closeTo(679.375, 1e-9));
    });

    test('ignores the tiers and modalities the app does not pay', () {
      final prices = parsePrices([
        for (final String suffix in [
          'text flex',
          'text priority',
          'text batch',
          'image',
          'audio',
        ]) ...[
          _sku('Generate content input token count gemini 9 flash $suffix', 1),
          _sku('Generate content output token count gemini 9 flash $suffix', 1),
        ],
        _sku(
            'Generate content cached input token count gemini 9 flash text', 1),
      ]);

      expect(prices, isEmpty);
    });

    test('names a length-split model by its id, at the short price', () {
      // The catalog lists gemini-2.5-flash only as -short-input /
      // -long-input variants; the id the API knows has no suffix. Listed
      // long first, so order cannot decide it.
      final prices = parsePrices([
        _sku(
            'Generate content input token count gemini 2.5 flash long input '
            'text',
            800),
        _sku(
            'Generate content input token count gemini 2.5 flash short input '
            'text',
            400),
        _sku(
            'Generate content output token count gemini 2.5 flash long output '
            'text',
            6000),
        _sku(
            'Generate content output token count gemini 2.5 flash short output '
            'text',
            3000),
      ]);

      expect(prices.keys, ['gemini-2.5-flash']);
      expect(prices['gemini-2.5-flash']!.input, closeTo(400, 1e-6));
      expect(prices['gemini-2.5-flash']!.output, closeTo(3000, 1e-6));
    });

    test('drops a model priced on one side only', () {
      // TTS models have a text input price and no text output price.
      final prices = parsePrices([
        _sku('Generate content input token count gemini 9 flash tts text', 1),
      ]);

      expect(prices, isEmpty);
    });
  });

  group('comparePrice', () {
    const ModelPrice current = ModelPrice(400, 3000);

    test('calls an identical price the same, not a trade-off', () {
      // Found on the first real run: gemini-2.5-flash and
      // gemini-3.5-flash-lite cost the same, and neither dominates.
      expect(comparePrice(const ModelPrice(400, 3000), current),
          PriceVerdict.same);
    });

    test('ranks only what is cheaper on both sides', () {
      expect(comparePrice(const ModelPrice(300, 3000), current),
          PriceVerdict.cheaper);
      expect(comparePrice(const ModelPrice(400, 3500), current),
          PriceVerdict.dearer);
      expect(comparePrice(const ModelPrice(300, 4000), current),
          PriceVerdict.tradeOff);
    });

    test('keeps an unpriced model apart from a dearer one', () {
      // A served model the catalog does not name may well be cheaper.
      expect(comparePrice(null, current), PriceVerdict.unpriced);
    });

    test('has no verdict when the configured model is unpriced', () {
      expect(comparePrice(const ModelPrice(1, 1), null), isNull);
    });
  });

  group('stableTextModel', () {
    test('accepts stable releases by version and tier', () {
      for (final String id in [
        'gemini-2.5-flash',
        'gemini-2.5-pro',
        'gemini-3.5-flash-lite',
        'gemini-3.8-flash',
      ]) {
        expect(stableTextModel.hasMatch(id), isTrue, reason: id);
      }
    });

    test('rejects previews, aliases, codenames and special-purpose models', () {
      // All of these were in models.list on 2026-10-28.
      for (final String id in [
        'gemini-3.1-flash-lite-preview',
        'gemini-flash-lite-latest',
        'gemini-3.8-flash-tts',
        'gemini-2.5-flash-image',
        'gemini-4-argon',
        'gemini-robotics-er-2-preview',
        'gemma-4-31b-it',
      ]) {
        expect(stableTextModel.hasMatch(id), isFalse, reason: id);
      }
    });
  });
}
