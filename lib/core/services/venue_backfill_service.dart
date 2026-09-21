import 'package:injectable/injectable.dart';

import '../../domain/usecases/backfill_venues_usecase.dart';
import '../analytics/analytics_service.dart';
import '../utils/constants.dart';
import 'preferences_checker.dart';

/// One-shot upgrade migration: schedules saved before the venue field
/// existed get their searchable venue filled by a single batched model
/// call, so the map fix (issue #56) reaches already-saved schedules too.
///
/// Runs fire-and-forget after startup. Success sets a preferences flag and
/// the run never repeats; any failure (offline, model error) leaves the
/// flag unset so the next launch simply tries again — untouched rows keep
/// the full-location map fallback in the meantime.
@lazySingleton
class VenueBackfillService {
  final BackfillVenuesUsecase _backfillVenues;
  final PreferencesChecker _preferences;
  final AnalyticsService _analytics;

  VenueBackfillService(
      this._backfillVenues, this._preferences, this._analytics);

  Future<void> run() async {
    try {
      if (await _preferences.hasKey(Constants.venueBackfillDoneKey)) return;
      await _backfillVenues.execute();
      await _preferences.setKey(Constants.venueBackfillDoneKey);
    } on Exception catch (error, stack) {
      // Recoverable failures (offline, model error) retry next launch.
      // Errors stay uncaught on purpose: the global platformDispatcher
      // handler reports them to Crashlytics as the bugs they are.
      _analytics.recordError(error, stack, reason: 'venue_backfill');
    }
  }
}
