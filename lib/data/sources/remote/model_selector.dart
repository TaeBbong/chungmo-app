/// Step 5:
/// Data source
///
/// Shared by every Firebase AI Logic source: which model a call runs on.

import 'package:firebase_ai/firebase_ai.dart';
import 'package:injectable/injectable.dart';

import '../../../core/services/model_config.dart';

/// Runs a model call on the configured models, stepping past a retired one.
///
/// A retired model fails every call, for every user, until someone notices.
/// When the backend answers that the model is not found, the call is made
/// again on the next model [ModelConfig] lists — ending at Google's
/// Flash-Lite alias — and the retired id is skipped for the rest of the
/// process. Any other failure is the caller's to handle: an exhausted
/// balance or quota refuses every model alike, so stepping to the next one
/// would only spend another call before the same refusal.
@lazySingleton
class ModelSelector {
  final ModelConfig _config;
  final Set<String> _retired = {};

  ModelSelector(this._config);

  /// Calls [call] with the first usable model and returns its result.
  ///
  /// Rethrows the last not-found error when every model is retired, so the
  /// caller still sees a service refusal.
  Future<T> run<T>(Future<T> Function(String model) call) async {
    final List<String> configured = _config.models;
    final List<String> usable =
        configured.where((model) => !_retired.contains(model)).toList();
    // Everything has failed before: try them all again rather than give up
    // without a call — a model the backend dropped can come back, and
    // Remote Config may have moved on in the meantime.
    final List<String> candidates = usable.isEmpty ? configured : usable;
    for (int i = 0; i < candidates.length; i++) {
      try {
        return await call(candidates[i]);
      } on FirebaseAIException catch (error) {
        if (!isModelNotFound(error)) rethrow;
        _retired.add(candidates[i]);
        if (i == candidates.length - 1) rethrow;
      }
    }
    throw StateError('ModelConfig listed no models');
  }

  /// Whether [error] says the requested model is not served.
  ///
  /// Recognised from the message because nothing else survives: the
  /// backend answers 404 NOT_FOUND, but firebase_ai 3.15.0's `parseError`
  /// (`lib/src/error.dart:151`) keeps only the message and drops `code` and
  /// `status`. Only the stem is matched, because the two backends word the
  /// rest differently: the Gemini API says "...for API version v1beta...
  /// Call ListModels", while the Firebase AI Logic proxy the app talks to
  /// says "...for API version v1main... Call ModelService.ListModels"
  /// (captured on a device, 2026-11-04). If the stem ever changes, the cost
  /// is today's behaviour — no fallback — never a misread outage.
  static bool isModelNotFound(FirebaseAIException error) =>
      _notFound.hasMatch(error.message);

  static final RegExp _notFound = RegExp(r'models/\S+ is not found');
}
