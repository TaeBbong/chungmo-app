import 'analytics_service.dart';

/// No-op [AnalyticsService] for tests and any build without analytics wired in.
///
/// Every call is a safe no-op, so code under test can depend on
/// [AnalyticsService] without touching Firebase. The app itself is wired to
/// [FirebaseAnalyticsService] via DI.
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
