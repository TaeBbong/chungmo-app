import 'package:chungmo/data/sources/local/app_preferences_local_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppPreferencesSourceImpl source;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    source = AppPreferencesSourceImpl();
  });

  test('a key that was never set is absent', () async {
    expect(await source.containsKey('onboarding_done'), isFalse);
  });

  test('marking a key makes it present', () async {
    await source.setBooleanKey('onboarding_done');

    expect(await source.containsKey('onboarding_done'), isTrue);
  });

  test('marks a key without a read coming first', () async {
    // Nothing calls initPrefs, so this used to go through a null check on a
    // preferences instance only `containsKey` ever populated — it worked
    // only because main happens to ask a question before answering one.
    SharedPreferences.setMockInitialValues({});
    final fresh = AppPreferencesSourceImpl();

    await expectLater(fresh.setBooleanKey('tour_done'), completes);
    expect(await fresh.containsKey('tour_done'), isTrue);
  });

  test('keys are independent of one another', () async {
    await source.setBooleanKey('tour_done');

    expect(await source.containsKey('tour_done'), isTrue);
    expect(await source.containsKey('venue_backfill_done'), isFalse);
  });

  test('marking a key twice is harmless', () async {
    await source.setBooleanKey('tour_done');
    await source.setBooleanKey('tour_done');

    expect(await source.containsKey('tour_done'), isTrue);
  });
}
