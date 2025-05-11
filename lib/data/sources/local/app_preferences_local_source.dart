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
  static SharedPreferences? _prefs;

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

  /// Sets given [key] with [value].
  @override
  Future<void> setBooleanKey(String key) async {
    await _prefs!.setBool(key, false);
  }
}
