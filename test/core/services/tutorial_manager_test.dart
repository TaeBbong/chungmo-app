import 'package:chungmo/core/services/tutorial_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TutorialManager.resolveTourMode', () {
    test('shows the full tour to a first-time user', () {
      expect(
        TutorialManager.resolveTourMode(
            sawVersionedTour: false, sawLegacyTour: false),
        TourMode.full,
      );
    });

    test('shows only the new steps to a legacy-tour user', () {
      expect(
        TutorialManager.resolveTourMode(
            sawVersionedTour: false, sawLegacyTour: true),
        TourMode.newFeaturesOnly,
      );
    });

    test('shows nothing once the versioned tour is done', () {
      expect(
        TutorialManager.resolveTourMode(
            sawVersionedTour: true, sawLegacyTour: false),
        isNull,
      );
      expect(
        TutorialManager.resolveTourMode(
            sawVersionedTour: true, sawLegacyTour: true),
        isNull,
      );
    });
  });

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

    testWidgets('reports targets unready while their widgets are unmounted',
        (tester) async {
      await buildManager(tester);

      manager.initTargets();

      // e.g. a launch-time share renders the loading branch without the
      // tour targets; showing then would abort but still report done.
      expect(manager.targetsReady, isFalse);
    });

    testWidgets('runs onDone only once the shown tour is skipped',
        (tester) async {
      final List<GlobalKey> keys = List.generate(4, (_) => GlobalKey());
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            // Centered so the step card (aligned above its target) stays
            // on-screen, as it does around the real home layout.
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final key in keys)
                SizedBox(key: key, width: 40, height: 40),
            ],
          ),
        ),
      ));
      final TutorialManager attached = TutorialManager(
        context: tester.element(find.byType(Scaffold)),
        linkInputKey: keys[0],
        resultBodyKey: keys[1],
        statsPageKey: keys[2],
        calendarPageKey: keys[3],
      );
      attached.initTargets();
      expect(attached.targetsReady, isTrue);

      bool done = false;
      attached.showTutorial(onDone: () => done = true);
      // The overlay is inserted post-frame and reveals its content only
      // after the focus animation completes; pump it frame by frame.
      for (int i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }

      expect(find.text('청첩장을 붙여넣으세요'), findsOneWidget);
      expect(done, isFalse);

      await tester.tap(find.text('건너뛰기'));
      await tester.pump();

      expect(done, isTrue);
    });
  });
}
