import 'package:chungmo/presentation/widgets/fade_slide_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('holds the child invisible through the delay, then eases in',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FadeSlideIn(
          delay: Duration(milliseconds: 100),
          child: Text('content'),
        ),
      ),
    );

    double opacity() => tester
        .widget<Opacity>(find.descendant(
            of: find.byType(FadeSlideIn), matching: find.byType(Opacity)))
        .opacity;

    // Mid-delay: the leading, clamped-to-zero part of the tween.
    await tester.pump(const Duration(milliseconds: 50));
    expect(opacity(), 0);

    // Past delay + entrance duration: settled.
    await tester.pump(const Duration(milliseconds: 400));
    expect(opacity(), 1);
  });
}
