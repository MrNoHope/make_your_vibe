import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  late SharedPreferences _preferences;

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  String? getString(String key) => _preferences.getString(key);

  bool getBool(String key, [bool fallback = false]) =>
      _preferences.getBool(key) ?? fallback;

  List<String> getStrings(String key) =>
      _preferences.getStringList(key) ?? const [];

  Future<void> setString(String key, String value) async {
    await _preferences.setString(key, value);
  }

  Future<void> setBool(String key, bool value) async {
    await _preferences.setBool(key, value);
  }

  Future<void> setStrings(String key, Iterable<String> value) async {
    await _preferences.setStringList(key, value.toList(growable: false));
  }

  List<Map<String, dynamic>> getMaps(String key) {
    try {
      final decoded = jsonDecode(_preferences.getString(key) ?? '[]') as List;
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> setMaps(
    String key,
    Iterable<Map<String, dynamic>> value,
  ) async {
    await _preferences.setString(key, jsonEncode(value.toList()));
  }
}
