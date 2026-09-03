import 'package:chungmo/data/repositories/pay_recommendation_repository.dart';
import 'package:chungmo/data/sources/remote/firebase_ai_pay_recommendation_impl.dart';
import 'package:chungmo/domain/entities/attendance.dart';
import 'package:chungmo/domain/entities/pay_recommendation.dart';
import 'package:chungmo/domain/entities/relation.dart';
import 'package:chungmo/domain/entities/schedule.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../mocks/mocks.mocks.dart';

Schedule buildSchedule({
  String link = 'https://invitation.com',
  Relation relation = Relation.friend,
  String relationNote = '',
  Attendance attendance = Attendance.attending,
  String location = '서울 웨딩홀',
  int pay = 0,
}) {
  return Schedule(
    link: link,
    thumbnail: '',
    groom: '철수',
    bride: '영희',
    date: DateTime(2026, 10, 10),
    location: location,
    relation: relation,
    relationNote: relationNote,
    attendance: attendance,
    pay: pay,
  );
}

void main() {
  group('buildHistoryBlock', () {
    test('should aggregate paid records per relation with count and average',
        () {
      final history = [
        buildSchedule(link: 'a', relation: Relation.friend, pay: 100000),
        buildSchedule(link: 'b', relation: Relation.friend, pay: 200000),
        buildSchedule(link: 'c', relation: Relation.coworker, pay: 50000),
      ];

      final block = FirebaseAiPayRecommendationImpl.buildHistoryBlock(history);

      expect(block, contains('친구: 2 records, average 150,000 KRW'));
      expect(block, contains('직장: 1 records, average 50,000 KRW'));
    });

    test('should exclude unpaid records and the target schedule itself', () {
      final history = [
        buildSchedule(link: 'target', relation: Relation.friend, pay: 999999),
        buildSchedule(link: 'unpaid', relation: Relation.friend, pay: 0),
        buildSchedule(link: 'kept', relation: Relation.friend, pay: 100000),
      ];

      final block = FirebaseAiPayRecommendationImpl.buildHistoryBlock(history,
          excludeLink: 'target');

      expect(block, contains('친구: 1 records, average 100,000 KRW'));
      expect(block, isNot(contains('999,999')));
    });

    test('should state that no records exist yet', () {
      expect(FirebaseAiPayRecommendationImpl.buildHistoryBlock(const []),
          '- No records yet.');
    });
  });

  group('buildPrompt', () {
    test('should carry every grounding signal into the prompt', () {
      final prompt = FirebaseAiPayRecommendationImpl.buildPrompt(
        target: buildSchedule(
          relation: Relation.coworker,
          relationNote: '인사만 해본 옆팀 동료',
          attendance: Attendance.absent,
          location: '신라호텔',
        ),
        history: [buildSchedule(link: 'past', pay: 100000)],
      );

      expect(prompt, contains('Venue: 신라호텔'));
      expect(prompt, contains('attendance: 불참'));
      expect(prompt, contains('Category: 직장'));
      expect(prompt, contains('"인사만 해본 옆팀 동료"'));
      expect(prompt, contains('친구: 1 records'));
      // The public statistics block must always ship with the prompt.
      expect(prompt, contains('Kakao Pay'));
      expect(prompt, contains('Incruit'));
    });

    test('should mark an empty relation note as not written', () {
      final prompt = FirebaseAiPayRecommendationImpl.buildPrompt(
        target: buildSchedule(relationNote: ''),
        history: const [],
      );

      expect(prompt, contains('(not written)'));
      expect(prompt, contains('- No records yet.'));
    });
  });

  group('parseResponse', () {
    test('should parse a valid payload', () {
      final result = FirebaseAiPayRecommendationImpl.parseResponse(
          '{"amount": 100000, "minAmount": 50000, "maxAmount": 200000, '
          '"reason": "친구니까 10만원이 국룰이에요."}');

      expect(
          result,
          const PayRecommendation(
              amount: 100000,
              minAmount: 50000,
              maxAmount: 200000,
              reason: '친구니까 10만원이 국룰이에요.'));
    });

    test('should reject a payload violating the amount contract', () {
      // The schema only enforces integer types, so the prompt's contract
      // (positive 10,000-KRW tiers, min <= amount <= max, non-empty
      // reason) must be re-checked before an amount reaches the pay field.
      const invalidPayloads = [
        // Inverted range: minAmount > amount.
        '{"amount": 90000, "minAmount": 100000, "maxAmount": 50000, '
            '"reason": "r"}',
        // amount above maxAmount.
        '{"amount": 300000, "minAmount": 50000, "maxAmount": 200000, '
            '"reason": "r"}',
        // Not a 10,000-KRW tier.
        '{"amount": 55000, "minAmount": 50000, "maxAmount": 100000, '
            '"reason": "r"}',
        // Non-positive amount.
        '{"amount": 0, "minAmount": 0, "maxAmount": 0, "reason": "r"}',
        // Missing reason.
        '{"amount": 100000, "minAmount": 50000, "maxAmount": 200000, '
            '"reason": "  "}',
      ];

      for (final payload in invalidPayloads) {
        expect(() => FirebaseAiPayRecommendationImpl.parseResponse(payload),
            throwsFormatException,
            reason: payload);
      }
    });
  });

  group('PayRecommendation.fallback', () {
    test('should suggest tiered defaults per relation', () {
      expect(PayRecommendation.fallback(Relation.family).amount, 300000);
      expect(PayRecommendation.fallback(Relation.friend).amount, 100000);
      expect(PayRecommendation.fallback(Relation.coworker).amount, 100000);
      expect(PayRecommendation.fallback(Relation.acquaintance).amount, 50000);
      expect(PayRecommendation.fallback(Relation.unset).amount, 50000);
    });

    test('should keep amount within its own range', () {
      for (final relation in Relation.values) {
        final fallback = PayRecommendation.fallback(relation);
        expect(fallback.minAmount, lessThanOrEqualTo(fallback.amount));
        expect(fallback.maxAmount, greaterThanOrEqualTo(fallback.amount));
        expect(fallback.reason, isNotEmpty);
      }
    });
  });

  group('PayRecommendationRepositoryImpl', () {
    test('should hand the local history to the source as entities', () async {
      final mockLocalSource = MockScheduleLocalSource();
      final mockRecommendationSource = MockPayRecommendationSource();
      final repository = PayRecommendationRepositoryImpl(
          mockRecommendationSource, mockLocalSource);
      final target = buildSchedule();
      const expected = PayRecommendation(
          amount: 100000, minAmount: 50000, maxAmount: 200000, reason: '친구니까');

      when(mockLocalSource.getAllSchedulesOnce()).thenAnswer((_) async => []);
      when(mockRecommendationSource.fetchRecommendation(
              target: anyNamed('target'), history: anyNamed('history')))
          .thenAnswer((_) async => expected);

      final result = await repository.recommendPay(target);

      expect(result, expected);
      verify(mockRecommendationSource.fetchRecommendation(
          target: target, history: [])).called(1);
    });
  });
}
