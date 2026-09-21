import 'package:chungmo/core/services/venue_backfill_service.dart';
import 'package:chungmo/core/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../mocks/mocks.mocks.dart';

void main() {
  late VenueBackfillService service;
  late MockBackfillVenuesUsecase usecase;
  late MockPreferencesChecker preferences;
  late MockAnalyticsService analytics;

  setUp(() {
    usecase = MockBackfillVenuesUsecase();
    preferences = MockPreferencesChecker();
    analytics = MockAnalyticsService();
    service = VenueBackfillService(usecase, preferences, analytics);
  });

  test('runs once and sets the done flag on success', () async {
    when(preferences.hasKey(any)).thenAnswer((_) async => false);
    when(preferences.setKey(any)).thenAnswer((_) async {});
    when(usecase.execute()).thenAnswer((_) async {});

    await service.run();

    verify(usecase.execute()).called(1);
    verify(preferences.setKey(Constants.venueBackfillDoneKey)).called(1);
  });

  test('never runs again once the flag is set', () async {
    when(preferences.hasKey(any)).thenAnswer((_) async => true);

    await service.run();

    verifyNever(usecase.execute());
  });

  test('a failed run reports the error and keeps the flag unset for a retry',
      () async {
    when(preferences.hasKey(any)).thenAnswer((_) async => false);
    when(usecase.execute()).thenThrow(Exception('offline'));

    await service.run();

    verify(analytics.recordError(any, any, reason: 'venue_backfill'))
        .called(1);
    verifyNever(preferences.setKey(any));
  });
}
