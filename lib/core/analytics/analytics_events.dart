/// Analytics event and parameter names.
///
/// Centralised so the taxonomy stays consistent across every call site and
/// matches the analytics design (docs/ANALYTICS.md). Names use lower_snake_case
/// and stay within Firebase limits (40-char event names, 100-char values).
class AnalyticsEvents {
  AnalyticsEvents._();

  // Activation funnel.
  static const String invitationLinkSubmitted = 'invitation_link_submitted';
  static const String parseStarted = 'parse_started';
  static const String parseSucceeded = 'parse_succeeded';
  static const String parseFailed = 'parse_failed';
  static const String scheduleSaved = 'schedule_saved';

  // Engagement.
  static const String scheduleOpened = 'schedule_opened';
  static const String locationMapOpened = 'location_map_opened';
  static const String attendanceRecorded = 'attendance_recorded';
  static const String giftRecorded = 'gift_recorded';
  static const String accountCopied = 'account_copied';
  static const String scheduleDeleted = 'schedule_deleted';
  static const String calendarViewed = 'calendar_viewed';
  static const String notificationOpened = 'notification_opened';
}

/// Parameter keys attached to [AnalyticsEvents].
class AnalyticsParams {
  AnalyticsParams._();

  static const String source = 'source';
  static const String durationMs = 'duration_ms';
  static const String reason = 'reason';
  static const String hasAccounts = 'has_accounts';
  static const String accountCount = 'account_count';
  static const String daysUntil = 'days_until';
  static const String status = 'status';
  static const String amountBucket = 'amount_bucket';
  static const String side = 'side';
  static const String view = 'view';
}

/// Durable user property names.
class AnalyticsUserProperties {
  AnalyticsUserProperties._();

  static const String savedScheduleCount = 'saved_schedule_count';
  static const String remoteSource = 'remote_source';
}

/// Reasons a parse attempt can fail.
///
/// Used both as the `reason` event parameter and as a Crashlytics key so
/// failures can be grouped by cause.
class ParseFailureReason {
  ParseFailureReason._();

  /// Could not fetch the invitation HTML.
  static const String crawl = 'crawl';

  /// The model returned a non-JSON or otherwise unparseable payload.
  static const String format = 'format';

  /// The JSON did not match the expected schema.
  static const String schema = 'schema';

  /// The request timed out.
  static const String timeout = 'timeout';

  /// Any other, unclassified failure.
  static const String unknown = 'unknown';
}
