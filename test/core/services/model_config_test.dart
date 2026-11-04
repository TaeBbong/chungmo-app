/// The order of models the app may use, given what Remote Config holds.
///
/// `RemoteModelConfig` itself needs a Firebase app; the decision it makes
/// from the value it reads is [ModelConfig.chain], tested here directly.
library;

import 'package:chungmo/core/services/model_config.dart';
import 'package:chungmo/core/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ModelConfig.chain', () {
    test('tries the configured model first, then the safety net', () {
      expect(ModelConfig.chain('gemini-9-flash-lite'),
          ['gemini-9-flash-lite', Constants.geminiSafetyNetModel]);
    });

    test('lists the safety net once when it is the configured model', () {
      // Someone points `model_name` at the alias itself: retrying the same
      // id after it was not found would only repeat the 404.
      expect(ModelConfig.chain(Constants.geminiSafetyNetModel),
          [Constants.geminiSafetyNetModel]);
    });

    test('falls back to the in-app default for a blank value', () {
      // What getString returns for a parameter published without a value,
      // or when setDefaults failed at startup.
      for (final String blank in ['', '   ']) {
        expect(ModelConfig.chain(blank),
            [Constants.geminiModel, Constants.geminiSafetyNetModel],
            reason: 'blank: "$blank"');
      }
    });

    test('ignores whitespace pasted around the id in the console', () {
      expect(ModelConfig.chain('  gemini-9-flash-lite \n').first,
          'gemini-9-flash-lite');
    });
  });
}
