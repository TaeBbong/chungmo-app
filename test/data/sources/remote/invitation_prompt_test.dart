import 'package:chungmo/data/sources/remote/invitation_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 15);

  group('extractionGuidelines', () {
    test('anchors the model to a zero-padded today', () {
      expect(extractionGuidelines(DateTime(2026, 9, 5)),
          contains('Today is 2026-09-05 (KST)'));
    });

    test('spells out the year-inference rule for year-less dates', () {
      final text = extractionGuidelines(now);
      expect(text, contains('omit the year'));
      expect(text, contains('stated weekday'));
      expect(text, contains('never\ninvent a month, day or time'));
    });
  });

  group('prompt builders', () {
    test('all three prompts carry the dated guidelines', () {
      expect(linkExtractionPrompt('본문', now: now),
          contains('Today is 2026-09-15'));
      expect(imageExtractionPrompt(now: now), contains('Today is 2026-09-15'));
      expect(textExtractionPrompt('문자', now: now),
          contains('Today is 2026-09-15'));
    });

    test('link prompt still embeds the crawled text', () {
      expect(linkExtractionPrompt('김민준 ♥ 이서연', now: now),
          contains('김민준 ♥ 이서연'));
    });
  });
}
