import 'package:chungmo/presentation/theme/dimens.dart';
import 'package:chungmo/presentation/widgets/adaptive_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps [child] inside a window [width] wide and returns what the child
/// actually got laid out to.
Future<Rect> _layoutIn(WidgetTester tester, double width,
    {double height = 800}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AdaptiveBody(
          child: Container(key: const ValueKey('body'), color: Colors.red),
        ),
      ),
    ),
  );
  final box =
      tester.renderObject<RenderBox>(find.byKey(const ValueKey('body')));
  final topLeft = box.localToGlobal(Offset.zero);
  return topLeft & box.size;
}

void main() {
  testWidgets('leaves a phone-width body exactly as it was', (tester) async {
    final rect = await _layoutIn(tester, 400);

    expect(rect.width, 400);
    expect(rect.left, 0);
  });

  testWidgets('does not add a wrapper below the cap', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);
    const child = SizedBox.shrink(key: ValueKey('body'));

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: AdaptiveBody(child: child)),
    ));

    // The phone layout is unchanged, not merely unaffected: nothing is
    // inserted between the body and its child.
    expect(find.byType(Align), findsNothing);
  });

  testWidgets('caps and centres a body wider than the maximum', (tester) async {
    final rect = await _layoutIn(tester, 900);

    expect(rect.width, Dimens.maxContentWidth);
    expect(rect.left, (900 - Dimens.maxContentWidth) / 2);
  });

  testWidgets('honours a wider cap when a pane asks for one', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveBody(
            maxWidth: 800,
            child: Container(key: const ValueKey('body'), color: Colors.red),
          ),
        ),
      ),
    );

    final box =
        tester.renderObject<RenderBox>(find.byKey(const ValueKey('body')));
    expect(box.size.width, 800);
  });

  testWidgets('takes the height of its child, not of the viewport',
      (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(900, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          // A bottom sheet measures its child; a body that always claimed
          // the whole viewport would push the sheet to full screen.
          bottomSheet: AdaptiveBody(
            child: SizedBox(key: ValueKey('sheet'), height: 120),
          ),
        ),
      ),
    );

    final sheet = tester.renderObject<RenderBox>(find.byType(AdaptiveBody));
    expect(sheet.size.height, 120);
  });
}
