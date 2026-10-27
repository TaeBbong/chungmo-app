/// Thrown when the model backend refused or could not serve a request.
///
/// Distinct from a parse failure: the invitation was never read, so
/// retrying the same input cannot succeed until the service recovers.
/// Covers an exhausted quota or prepaid balance, a retired model, and any
/// other service-side refusal.
class RemoteUnavailableException implements Exception {
  /// The backend's own description, kept for logs and Crashlytics.
  final String message;

  const RemoteUnavailableException(this.message);

  @override
  String toString() => 'RemoteUnavailableException: $message';
}
