import 'package:chungmo/core/analytics/analytics_service.dart';
import 'package:chungmo/core/analytics/noop_analytics_service.dart';
import 'package:chungmo/core/di/di.dart';
import 'package:chungmo/domain/entities/account.dart';
import 'package:chungmo/presentation/widgets/account_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    getIt.registerSingleton<AnalyticsService>(const NoopAnalyticsService());
  });

  tearDown(() => getIt.reset());

  Widget harness(Account groomAccount) {
    return MaterialApp(
      home: Scaffold(
        body: AccountSection(
          groomAccounts: [groomAccount],
          brideAccounts: const [],
        ),
      ),
    );
  }

  const Account first =
      Account(bank: '국민', number: '123-45-6789', holder: '김철수');
  const Account second =
      Account(bank: '신한', number: '987-65-4321', holder: '박영호');

  testWidgets('copied check resets when the tile shows a different account',
      (tester) async {
    await tester.pumpWidget(harness(first));
    await tester.tap(find.text('마음 전하실 곳'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('국민 123-45-6789'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    // Same tree position, different account: the unkeyed tile reuses its
    // State, so the check (and its reset timer) must not carry over.
    await tester.pumpWidget(harness(second));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_rounded), findsNothing);
    expect(find.byIcon(Icons.copy), findsOneWidget);
  });
}
