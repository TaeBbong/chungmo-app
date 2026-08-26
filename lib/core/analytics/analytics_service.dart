/// Abstract analytics and crash-reporting facade.
///
/// The app talks to this instead of Firebase directly, so instrumentation is
/// decoupled from the backend and can be swapped or disabled (e.g. the
/// [NoopAnalyticsService] used in tests and before the Firebase implementation
/// is wired in). Implementations map these calls onto Firebase Analytics and
/// Crashlytics. See docs/ANALYTICS.md for the event taxonomy.
abstract class AnalyticsService {
  /// Logs a taxonomy event with optional parameters.
  Future<void> logEvent(String name, {Map<String, Object?>? parameters});

  /// Records the current screen for screen-view reporting.
  Future<void> setCurrentScreen(String screenName);

  /// Sets a durable user property. A null [value] clears it.
  Future<void> setUserProperty(String name, String? value);

  /// Reports a non-fatal error, with an optional [reason] used to group it and
  /// optional custom [keys] attached to the report.
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    Map<String, Object?>? keys,
  });
}
