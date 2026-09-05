import 'package:chungmo/core/analytics/analytics_service.dart';
import 'package:chungmo/core/analytics/noop_analytics_service.dart';
import 'package:chungmo/core/di/di.dart';
import 'package:chungmo/domain/entities/pay_recommendation.dart';
import 'package:chungmo/domain/entities/relation.dart';
import 'package:chungmo/domain/entities/schedule.dart';
import 'package:chungmo/domain/usecases/usecases.dart';
import 'package:chungmo/presentation/pages/record_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../mocks/mocks.mocks.dart';

void main() {
  late MockRecommendPayUsecase recommend;
  late MockEditScheduleUsecase edit;

  setUp(() {
    recommend = MockRecommendPayUsecase();
    edit = MockEditScheduleUsecase();
    getIt.registerSingleton<RecommendPayUsecase>(recommend);
    getIt.registerSingleton<EditScheduleUsecase>(edit);
    getIt.registerSingleton<AnalyticsService>(const NoopAnalyticsService());
  });

  tearDown(() => getIt.reset());

  Schedule buildSchedule({int pay = 0}) {
    return Schedule(
      link: 'https://invitation.com',
      thumbnail: '',
      groom: '철수',
      bride: '영희',
      date: DateTime(2026, 10, 10),
      location: '서울 웨딩홀',
      relation: Relation.friend,
      pay: pay,
    );
  }

  const PayRecommendation recommendation = PayRecommendation(
    amount: 130000,
    reason: '친구 사이 평균을 감안했어요.',
    minAmount: 100000,
    maxAmount: 150000,
  );

  String payFieldText(WidgetTester tester) => tester
      .widget<TextField>(find.byKey(const ValueKey('pay-field')))
      .controller!
      .text;

  Future<void> requestRecommendation(WidgetTester tester) async {
    // The button sits below the fold of the test viewport.
    await tester.ensureVisible(find.text('AI에게 축의금 추천받기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI에게 축의금 추천받기'));
    await tester.pumpAndSettle();
  }

  testWidgets('fills an empty amount field when a recommendation arrives',
      (tester) async {
    when(recommend.execute(any)).thenAnswer((_) async => recommendation);
    await tester.pumpWidget(
        MaterialApp(home: RecordPage(schedule: buildSchedule(pay: 0))));

    await requestRecommendation(tester);

    // Saving right away must record the shown amount, not 0원 — the
    // regression this guards: a suggestion shown on a blank form used to
    // stay display-only until '이 금액 적용' was tapped.
    expect(payFieldText(tester), '130000');
  });

  testWidgets('does not resurrect a cleared amount on save emissions',
      (tester) async {
    when(recommend.execute(any)).thenAnswer((_) async => recommendation);
    when(edit.execute(any)).thenThrow(Exception('save failed'));
    await tester.pumpWidget(
        MaterialApp(home: RecordPage(schedule: buildSchedule(pay: 0))));

    await requestRecommendation(tester);
    expect(payFieldText(tester), '130000');

    // The user clears the autofilled amount to record attendance only;
    // the save emissions must not run the autofill again.
    await tester.enterText(find.byKey(const ValueKey('pay-field')), '');
    await tester.ensureVisible(find.byKey(const ValueKey('record-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('record-save')));
    await tester.pumpAndSettle();

    expect(payFieldText(tester), '');
  });

  testWidgets('autofills again when the same instance returns after invalidation',
      (tester) async {
    // Fallback recommendations are canonicalized consts: a re-request can
    // hand back the identical object, which must still count as an arrival
    // once an invalidation cleared the previous one.
    when(recommend.execute(any)).thenAnswer((_) async => recommendation);
    await tester.pumpWidget(
        MaterialApp(home: RecordPage(schedule: buildSchedule(pay: 0))));

    await requestRecommendation(tester);
    expect(payFieldText(tester), '130000');

    await tester.enterText(find.byKey(const ValueKey('pay-field')), '');
    // Changing the relation invalidates the shown recommendation.
    await tester.tap(find.text('직장'));
    await tester.pumpAndSettle();

    await requestRecommendation(tester);

    expect(payFieldText(tester), '130000');
  });

  testWidgets('never overwrites an amount the user already has',
      (tester) async {
    when(recommend.execute(any)).thenAnswer((_) async => recommendation);
    await tester.pumpWidget(
        MaterialApp(home: RecordPage(schedule: buildSchedule(pay: 50000))));

    await requestRecommendation(tester);

    expect(payFieldText(tester), '50000');
    // The explicit apply button still replaces it.
    await tester
        .ensureVisible(find.byKey(const ValueKey('apply-recommendation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('apply-recommendation')));
    await tester.pumpAndSettle();
    expect(payFieldText(tester), '130000');
  });
}
