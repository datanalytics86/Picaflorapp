import 'package:shared_preferences/shared_preferences.dart';

/// Almacén mínimo. El fallback de arranque no usa APIs de test.
abstract class KeyValueStore {
  String? getString(String key);
  bool? getBool(String key);
  double? getDouble(String key);
  Future<bool> setString(String key, String value);
  Future<bool> setBool(String key, bool value);
  Future<bool> setDouble(String key, double value);
  Future<bool> remove(String key);
}

class SharedPrefsStore implements KeyValueStore {
  SharedPrefsStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  bool? getBool(String key) => _prefs.getBool(key);

  @override
  double? getDouble(String key) => _prefs.getDouble(key);

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<bool> remove(String key) => _prefs.remove(key);

  @override
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  @override
  Future<bool> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);

  @override
  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);
}

/// Memoria vacía. No marca el onboarding como hecho.
class MemoryKeyValueStore implements KeyValueStore {
  final Map<String, Object> _data = {};

  @override
  bool? getBool(String key) {
    final v = _data[key];
    return v is bool ? v : null;
  }

  @override
  double? getDouble(String key) {
    final v = _data[key];
    return v is double ? v : null;
  }

  @override
  String? getString(String key) {
    final v = _data[key];
    return v is String ? v : null;
  }

  @override
  Future<bool> remove(String key) async {
    _data.remove(key);
    return true;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _data[key] = value;
    return true;
  }
}
