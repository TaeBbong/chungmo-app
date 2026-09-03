/// Step 5:
/// Data source
///
/// CRUD based data source implement with remote/local source

import 'dart:async';
import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:injectable/injectable.dart';

import '../../../core/utils/constants.dart';
import '../../../domain/entities/pay_recommendation.dart';
import '../../../domain/entities/relation.dart';
import '../../../domain/entities/schedule.dart';
import 'pay_recommendation_source.dart';

/// JSON schema forced on the recommendation response.
const Map<String, Object> _recommendationJsonSchema = {
  "type": "object",
  "title": "PayRecommendation",
  "description": "Congratulatory gift amount recommendation",
  "properties": {
    "amount": {
      "type": "integer",
      "description": "Recommended amount in KRW, a multiple of 10000"
    },
    "minAmount": {
      "type": "integer",
      "description": "Reasonable lower bound in KRW, a multiple of 10000"
    },
    "maxAmount": {
      "type": "integer",
      "description": "Reasonable upper bound in KRW, a multiple of 10000"
    },
    "reason": {
      "type": "string",
      "description": "One or two friendly, witty Korean sentences explaining "
          "the amount, citing the grounding data actually used"
    }
  },
  "required": ["amount", "minAmount", "maxAmount", "reason"]
};

/// Public Korean gift-money statistics injected into every prompt so the
/// model grounds its number in real data instead of its own prior.
///
/// Sources: Kakao Pay transfer-data coverage (2024) and the Incruit survey
/// of 844 office workers (2025). Update alongside newer surveys; a future
/// crowd-sourced dataset can replace this block via a new
/// [PayRecommendationSource] implementation.
const String _referenceStats = '''
- Kakao Pay transfer data: the average wedding gift rose from 73,000 KRW
  (2021) to 90,000 KRW (2024). By age group: 20s about 60,000, 30s-40s about
  100,000, 50s-60s about 120,000 KRW.
- Incruit 2025 survey (844 office workers) on coworker weddings: 100,000 KRW
  was the most common answer (61.8%), then 50,000 KRW (32.8%). The ranking
  held regardless of how close the coworker was.
- Korean etiquette: amounts move in 50,000 KRW tiers (50k/100k/150k/200k+).
  Attending in person should cover the meal - hotel wedding meals often cost
  100,000+ KRW, so attendees at hotel venues lean one tier higher. Guests who
  cannot attend usually go one tier lower.''';

@LazySingleton(as: PayRecommendationSource, env: ['firebase'])
class FirebaseAiPayRecommendationImpl implements PayRecommendationSource {
  FirebaseAiPayRecommendationImpl();

  GenerativeModel _buildModel() {
    return FirebaseAI.googleAI().generativeModel(
      model: Constants.geminiModel,
      generationConfig: GenerationConfig(
          responseJsonSchema: _recommendationJsonSchema,
          responseMimeType: "application/json"),
    );
  }

  @override
  Future<PayRecommendation> fetchRecommendation({
    required Schedule target,
    required List<Schedule> history,
  }) async {
    try {
      final prompt = [Content.text(buildPrompt(target: target, history: history))];
      final response = await _buildModel().generateContent(prompt);
      final String? text = response.text;
      if (text == null) {
        throw Exception('[-] Empty recommendation response');
      }
      return parseResponse(text);
    } on FormatException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (e) {
      throw Exception('[-] Failed to fetch recommendation: $e');
    }
  }

  /// Decodes and validates the model's JSON payload.
  ///
  /// The response schema only enforces integer types; the amount contract
  /// (positive 10,000-KRW tiers, minAmount <= amount <= maxAmount, a
  /// non-empty reason) lives in the prompt, so a payload violating it is
  /// rejected here and callers degrade to [PayRecommendation.fallback]
  /// instead of applying a nonsensical amount.
  /// Amounts must land on 10,000-KRW tiers, the unit Korean gift money
  /// moves in.
  static const int _tierUnit = 10000;

  static PayRecommendation parseResponse(String text) {
    final Map<String, dynamic> json = jsonDecode(text) as Map<String, dynamic>;
    // A missing field is the same contract violation as an invalid one, so
    // it surfaces as a FormatException rather than a TypeError.
    final int? amount = (json['amount'] as num?)?.toInt();
    final int? minAmount = (json['minAmount'] as num?)?.toInt();
    final int? maxAmount = (json['maxAmount'] as num?)?.toInt();
    final String reason = (json['reason'] as String?)?.trim() ?? '';
    if (amount == null || minAmount == null || maxAmount == null) {
      throw const FormatException('[-] Missing recommendation field');
    }
    final bool validTiers = [amount, minAmount, maxAmount]
        .every((value) => value > 0 && value % _tierUnit == 0);
    if (!validTiers ||
        minAmount > amount ||
        amount > maxAmount ||
        reason.isEmpty) {
      throw const FormatException('[-] Invalid recommendation payload');
    }
    return PayRecommendation(
      amount: amount,
      minAmount: minAmount,
      maxAmount: maxAmount,
      reason: reason,
    );
  }

  /// Assembles the grounded prompt. Static so tests can assert on the
  /// exact context handed to the model without touching Firebase.
  static String buildPrompt({
    required Schedule target,
    required List<Schedule> history,
  }) {
    return '''You are a Korean wedding gift-money (축의금) advisor.
Recommend how much the user should give for the wedding below and return
pure JSON matching the response schema.

[Wedding]
- Couple: ${target.groom} & ${target.bride}
- Venue: ${target.location.isEmpty ? 'unknown' : target.location}
- The user's attendance: ${target.attendance.label}

[Relationship]
- Category: ${target.relation.label}
- In the user's own words: ${target.relationNote.isEmpty ? '(not written)' : '"${target.relationNote}"'}

[The user's own giving history]
${buildHistoryBlock(history, excludeLink: target.link)}

[Korean public statistics for grounding]
$_referenceStats

Rules:
- Ground the amount in the statistics above and the user's own history;
  never invent numbers. Amounts are multiples of 10,000 KRW in the usual
  tiers, with minAmount <= amount <= maxAmount.
- If the venue name suggests a hotel wedding and the user attends, lean one
  tier higher.
- Weigh the relationship nuance written in the user's own words over the
  bare category: distance, how long since they last met, awkward history.
- reason: one or two Korean sentences, friendly and lightly witty, that
  mention which data the amount is based on.''';
  }

  /// Summarizes the user's recorded amounts per relation, e.g.
  /// `- 친구: 3 records, average 100,000 KRW`.
  ///
  /// The target schedule itself is excluded so its current value doesn't
  /// anchor the recommendation.
  static String buildHistoryBlock(List<Schedule> history,
      {String? excludeLink}) {
    final List<Schedule> paid = history
        .where((s) => s.pay > 0 && s.link != excludeLink)
        .toList();
    if (paid.isEmpty) {
      return '- No records yet.';
    }

    final Map<Relation, List<int>> byRelation = {};
    for (final Schedule schedule in paid) {
      byRelation.putIfAbsent(schedule.relation, () => []).add(schedule.pay);
    }
    return byRelation.entries.map((entry) {
      final List<int> pays = entry.value;
      final int average = pays.reduce((a, b) => a + b) ~/ pays.length;
      return '- ${entry.key.label}: ${pays.length} records, '
          'average ${_formatKrw(average)} KRW';
    }).join('\n');
  }

  static String _formatKrw(int amount) {
    return amount.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  }
}
