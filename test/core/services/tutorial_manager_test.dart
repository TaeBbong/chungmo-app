import 'package:chungmo/core/services/tutorial_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TutorialManager.initTargets', () {
    late TutorialManager manager;

    Future<void> buildManager(WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      manager = TutorialManager(
        context: tester.element(find.byType(Scaffold)),
        linkInputKey: GlobalKey(),
        resultBodyKey: GlobalKey(),
        statsPageKey: GlobalKey(),
        calendarPageKey: GlobalKey(),
      );
    }

    testWidgets('builds the full four-step tour by default', (tester) async {
      await buildManager(tester);

      manager.initTargets();

      expect(manager.targetCount, 4);
    });

    testWidgets('keeps only the new-feature step for returning users',
        (tester) async {
      await buildManager(tester);

      manager.initTargets(newFeaturesOnly: true);

      expect(manager.targetCount, 1);
    });

    testWidgets('rebuilds instead of accumulating targets', (tester) async {
      await buildManager(tester);

      manager.initTargets();
      manager.initTargets();

      expect(manager.targetCount, 4);
    });
  });
}
