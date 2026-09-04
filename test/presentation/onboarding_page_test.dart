import 'package:chungmo/presentation/pages/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OnboardingPage', () {
    Future<void> pumpPage(WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingPage()));
    }

    Future<void> tapNext(WidgetTester tester) async {
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
    }

    testWidgets('walks through the four slides ending in the CTA',
        (tester) async {
      await pumpPage(tester);

      expect(find.text('청첩장, 붙여넣기만 하세요'), findsOneWidget);
      expect(find.text('건너뛰기'), findsOneWidget);

      await tapNext(tester);
      expect(find.text('축의금, 얼마가 적당할까요?'), findsOneWidget);

      await tapNext(tester);
      expect(find.text('일정도 지출도 한눈에'), findsOneWidget);

      await tapNext(tester);
      expect(find.text('예식 전날 미리 알려드려요'), findsOneWidget);
      expect(find.text('시작하기'), findsOneWidget);
      // The skip affordance disappears on the final slide.
      expect(find.text('건너뛰기'), findsNothing);
    });

    testWidgets('mentions the AI recommendation grounding on slide two',
        (tester) async {
      await pumpPage(tester);
      await tapNext(tester);

      expect(find.textContaining('AI가 추천해요'), findsOneWidget);
    });
  });
}
