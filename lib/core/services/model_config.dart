import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../utils/constants.dart';

/// Which Gemini models the Firebase AI Logic calls may use.
///
/// The id is configuration, not code: Gemini models are retired every few
/// months, and a constant compiled into each release takes a store review
/// to replace. See docs/MODEL_SELECTION.md for the policy behind the value.
abstract class ModelConfig {
  /// Starts reading the remote value. Safe to call before the network is up.
  Future<void> init();

  /// The models to try, in order: the configured one, then the safety net.
  List<String> get models;

  /// The order [models] reports for a configured [name].
  ///
  /// An empty or blank value — a parameter published without one, or
  /// defaults that could not be set — falls back to the in-app default
  /// rather than to nothing. The safety net always comes last and never
  /// twice.
  static List<String> chain(String name) {
    final String configured =
        name.trim().isEmpty ? Constants.geminiModel : name.trim();
    return [
      configured,
      if (configured != Constants.geminiSafetyNetModel)
        Constants.geminiSafetyNetModel,
    ];
  }
}

/// [ModelConfig] backed by the Remote Config parameter `model_name`.
///
/// Follows Firebase's "change the model name remotely" pattern for AI
/// Logic: in-app defaults, a fetch, and a real-time listener that activates
/// a published change at once. One deliberate difference from the guide's
/// sample: startup does not wait for the fetch. The in-app default is a
/// model that works, the value is read only when the user starts a parse,
/// and a slow network must not hold the splash screen.
@LazySingleton(as: ModelConfig)
class RemoteModelConfig implements ModelConfig {
  /// The Remote Config parameter holding the model id.
  static const String modelNameKey = 'model_name';

  FirebaseRemoteConfig get _remoteConfig => FirebaseRemoteConfig.instance;

  StreamSubscription<RemoteConfigUpdate>? _updates;

  @override
  Future<void> init() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        // The SDK's own default.
        fetchTimeout: const Duration(minutes: 1),
        // The interval Firebase's AI Logic guide uses. Urgent changes do
        // not wait for it: the real-time listener below delivers them.
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await _remoteConfig
          .setDefaults(const {modelNameKey: Constants.geminiModel});
    } on Exception catch (error) {
      // Without defaults the parameter reads empty, which [ModelConfig.chain]
      // already maps to the in-app default — nothing is lost but the remote
      // value, so startup carries on.
      debugPrint('[-] Remote Config setup failed: $error');
    }
    unawaited(_fetch());
    // An error handler is required: without one a dropped real-time
    // connection would reach the zone's uncaught-error handler and be
    // reported to Crashlytics as a fatal.
    _updates ??= _remoteConfig.onConfigUpdated.listen(
      (_) => unawaited(_activate()),
      onError: (Object error) =>
          debugPrint('[-] Remote Config updates stopped: $error'),
    );
  }

  Future<void> _fetch() async {
    try {
      await _remoteConfig.fetchAndActivate();
    } on Exception catch (error) {
      // Offline or throttled: the last activated value, or the default,
      // stays in force.
      debugPrint('[-] Remote Config fetch failed: $error');
    }
  }

  Future<void> _activate() async {
    try {
      await _remoteConfig.activate();
    } on Exception catch (error) {
      debugPrint('[-] Remote Config activate failed: $error');
    }
  }

  @override
  List<String> get models =>
      ModelConfig.chain(_remoteConfig.getString(modelNameKey));
}

/// [ModelConfig] with a fixed list, for tests and anything that must not
/// touch Firebase.
class FixedModelConfig implements ModelConfig {
  @override
  final List<String> models;

  const FixedModelConfig(this.models);

  @override
  Future<void> init() async {}
}
