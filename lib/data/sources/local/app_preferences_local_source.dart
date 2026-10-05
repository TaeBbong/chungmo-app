import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstract data source for SharedPreferences.
abstract class AppPreferencesLocalSource {
  /// Checks whether the given [key] exists in SharedPreferences.
  Future<bool> containsKey(String key);

  /// Initializes SharedPreferences instance (optional manual call).
  Future<void> initPrefs();

  Future<void> setBooleanKey(String key);
}

@LazySingleton(as: AppPreferencesLocalSource)
class AppPreferencesSourceImpl implements AppPreferencesLocalSource {
  /// Per instance, not static: there is one of these, so a static adds
  /// nothing except state that outlives it and leaks between tests.
  SharedPreferences? _prefs;

  /// Internal getter for SharedPreferences instance.
  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Optional manual initialization.
  @override
  Future<void> initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Checks if the given [key] exists.
  @override
  Future<bool> containsKey(String key) async {
    final instance = await prefs; // Uses the getter
    return instance.containsKey(key);
  }

  /// Records that [key] happened.
  ///
  /// Only the key's presence is ever read back — `containsKey` is the whole
  /// interface — so the stored value carries no meaning.
  ///
  /// Goes through the getter rather than `_prefs!`: nothing calls
  /// [initPrefs], and this is only safe today because `main` happens to ask
  /// `containsKey` first. A caller that marked a key before reading one
  /// would have thrown on a null check.
  @override
  Future<void> setBooleanKey(String key) async {
    final instance = await prefs;
    await instance.setBool(key, false);
  }
}
