import 'package:injectable/injectable.dart';

import '../../data/sources/local/app_preferences_local_source.dart';

@injectable
class PreferencesChecker {
  final AppPreferencesLocalSource _preferencesSource;

  /// Constructor with dependency injection.
  PreferencesChecker(this._preferencesSource);

  // Future<void> init() async {
  //   await _preferencesSource.initPrefs();
  // }

  /// Checks if the given [key] exists in SharedPreferences.
  Future<bool> hasKey(String key) async {
    return await _preferencesSource.containsKey(key);
  }

  /// Sets given [key] with value `true`.
  Future<void> setKey(String key) async {
    await _preferencesSource.setBooleanKey(key);
  }
}
