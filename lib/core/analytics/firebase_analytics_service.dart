import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:injectable/injectable.dart';

import 'analytics_service.dart';

/// Firebase-backed [AnalyticsService].
///
/// Maps taxonomy events onto Firebase Analytics and forwards errors to
/// Crashlytics. Analytics only accepts String/num parameter values, so
/// [_sanitize] drops nulls and coerces booleans to 0/1.
@LazySingleton(as: AnalyticsService)
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;
  FirebaseCrashlytics get _crashlytics => FirebaseCrashlytics.instance;

  @override
  Future<void> logEvent(String name, {Map<String, Object?>? parameters}) {
    return _analytics.logEvent(name: name, parameters: _sanitize(parameters));
  }

  @override
  Future<void> setCurrentScreen(String screenName) {
    return _analytics.logScreenView(screenName: screenName);
  }

  @override
  Future<void> setUserProperty(String name, String? value) {
    return _analytics.setUserProperty(name: name, value: value);
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    Map<String, Object?>? keys,
  }) async {
    if (keys != null) {
      for (final MapEntry<String, Object?> entry in keys.entries) {
        final Object? value = entry.value;
        if (value != null) await _crashlytics.setCustomKey(entry.key, value);
      }
    }
    await _crashlytics.recordError(error, stack, reason: reason);
  }

  /// Keeps only non-null values and coerces booleans to integers, which is what
  /// Firebase Analytics accepts as parameter values.
  Map<String, Object>? _sanitize(Map<String, Object?>? parameters) {
    if (parameters == null) return null;
    final Map<String, Object> result = <String, Object>{};
    parameters.forEach((String key, Object? value) {
      if (value == null) return;
      result[key] = value is bool ? (value ? 1 : 0) : value;
    });
    return result.isEmpty ? null : result;
  }
}
