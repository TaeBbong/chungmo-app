import 'package:injectable/injectable.dart';

import 'analytics_service.dart';

/// Default no-op [AnalyticsService].
///
/// Registered until the Firebase-backed implementation is wired in, and used in
/// tests. Every call is a safe no-op, so instrumentation can be added across the
/// app without a runtime dependency on Firebase Analytics or Crashlytics.
@LazySingleton(as: AnalyticsService)
class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  Future<void> logEvent(String name, {Map<String, Object?>? parameters}) async {}

  @override
  Future<void> setCurrentScreen(String screenName) async {}

  @override
  Future<void> setUserProperty(String name, String? value) async {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    Map<String, Object?>? keys,
  }) async {}
}
