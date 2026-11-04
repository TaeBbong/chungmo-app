/// Which model a call runs on when the configured one has been retired.
library;

import 'package:chungmo/core/services/model_config.dart';
import 'package:chungmo/data/sources/remote/model_selector.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Gemini API's answer for a model it no longer serves, as measured
/// against a retired id (gemini-1.5-flash) on 2026-10-28.
ServerException _notFound(String model) => ServerException(
    'models/$model is not found for API version v1beta, or is not supported '
    'for generateContent. Call ListModels to see the list of available '
    'models and their supported methods.');

/// A backend that has retired [retired] and answers every other model with
/// its own name; records the order the models were asked in.
class _Backend {
  final Set<String> retired;
  final List<String> asked = [];

  _Backend({this.retired = const {}});

  Future<String> call(String model) async {
    asked.add(model);
    if (retired.contains(model)) throw _notFound(model);
    return model;
  }
}

void main() {
  const List<String> models = ['pinned', 'alias'];

  test('runs on the configured model while it is served', () async {
    final backend = _Backend();
    final selector = ModelSelector(const FixedModelConfig(models));

    expect(await selector.run(backend.call), 'pinned');
    expect(backend.asked, ['pinned']);
  });

  test('steps to the next model when the configured one is retired', () async {
    final backend = _Backend(retired: {'pinned'});
    final selector = ModelSelector(const FixedModelConfig(models));

    expect(await selector.run(backend.call), 'alias');
    expect(backend.asked, ['pinned', 'alias']);
  });

  test('does not ask for a retired model again in the same process', () async {
    final backend = _Backend(retired: {'pinned'});
    final selector = ModelSelector(const FixedModelConfig(models));

    await selector.run(backend.call);
    backend.asked.clear();
    await selector.run(backend.call);

    expect(backend.asked, ['alias'],
        reason: 'every later parse would otherwise pay for the 404 first');
  });

  test('surfaces the refusal when every model is retired', () async {
    final backend = _Backend(retired: {'pinned', 'alias'});
    final selector = ModelSelector(const FixedModelConfig(models));

    await expectLater(
        selector.run(backend.call), throwsA(isA<ServerException>()));
    expect(backend.asked, ['pinned', 'alias']);
  });

  test('tries every model again once all have failed before', () async {
    // A dropped model can come back, and Remote Config can move on; giving
    // up without a call would leave the app dead until it restarts.
    final backend = _Backend(retired: {'pinned', 'alias'});
    final selector = ModelSelector(const FixedModelConfig(models));
    await expectLater(selector.run(backend.call), throwsA(anything));

    backend.retired.clear();
    backend.asked.clear();

    expect(await selector.run(backend.call), 'pinned');
  });

  group('does not step past a refusal that is not a retired model', () {
    // An exhausted balance or quota refuses every model alike: a second
    // call would only spend more before the same answer.
    for (final FirebaseAIException refusal in [
      ServerException('Your prepayment credits are depleted.'),
      QuotaExceeded('Quota exceeded for model'),
    ]) {
      test(refusal.runtimeType.toString(), () async {
        final List<String> asked = [];
        final selector = ModelSelector(const FixedModelConfig(models));

        await expectLater(selector.run((model) async {
          asked.add(model);
          throw refusal;
        }), throwsA(same(refusal)));
        expect(asked, ['pinned']);
      });
    }

    test('lets a non-SDK failure through untouched', () async {
      final List<String> asked = [];
      final selector = ModelSelector(const FixedModelConfig(models));

      await expectLater(selector.run<String>((model) async {
        asked.add(model);
        throw const FormatException('unreadable answer');
      }), throwsA(isA<FormatException>()));
      expect(asked, ['pinned']);
    });
  });

  group('isModelNotFound', () {
    test('recognises the Gemini API wording', () {
      expect(
          ModelSelector.isModelNotFound(_notFound('gemini-2.5-flash')), isTrue);
    });

    test('does not read a billing refusal as a retired model', () {
      expect(
          ModelSelector.isModelNotFound(
              ServerException('Your prepayment credits are depleted.')),
          isFalse);
    });
  });
}
