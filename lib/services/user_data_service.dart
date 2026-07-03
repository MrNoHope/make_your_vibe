import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class UserLibraryData {
  const UserLibraryData({
    this.likedSongIds = const [],
    this.recentlyPlayedSongIds = const [],
    this.savedVibes = const [],
    this.playlists = const {},
  });

  final List<String> likedSongIds;
  final List<String> recentlyPlayedSongIds;
  final List<String> savedVibes;
  final Map<String, List<String>> playlists;

  Map<String, dynamic> toJson() {
    return {
      'likedSongIds': likedSongIds,
      'recentlyPlayedSongIds': recentlyPlayedSongIds,
      'savedVibes': savedVibes,
      'playlists': playlists,
    };
  }

  factory UserLibraryData.fromJson(Map<String, dynamic> json) {
    return UserLibraryData(
      likedSongIds: _stringList(json['likedSongIds']),
      recentlyPlayedSongIds: _stringList(json['recentlyPlayedSongIds']),
      savedVibes: _stringList(json['savedVibes']),
      playlists: _playlistMap(json['playlists']),
    );
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) {
      return [];
    }

    return value.map((item) => item.toString()).toList();
  }

  static Map<String, List<String>> _playlistMap(Object? value) {
    if (value is! Map) {
      return {};
    }

    return value.map((key, item) {
      return MapEntry(key.toString(), _stringList(item));
    });
  }
}

abstract class UserDataService {
  Future<void> init();

  Future<UserLibraryData> loadLibrary(String email);

  Future<void> saveLibrary(String email, UserLibraryData data);
}

class LocalUserDataService implements UserDataService {
  static const dataKeyPrefix = 'make_your_vibe_user_data';

  late final SharedPreferences prefs;

  @override
  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<UserLibraryData> loadLibrary(String email) async {
    final raw = prefs.getString(_keyFor(email));

    if (raw == null || raw.isEmpty) {
      return const UserLibraryData();
    }

    final Object? decoded;

    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return const UserLibraryData();
    }

    if (decoded is! Map) {
      return const UserLibraryData();
    }

    return UserLibraryData.fromJson(Map<String, dynamic>.from(decoded));
  }

  @override
  Future<void> saveLibrary(String email, UserLibraryData data) {
    return prefs.setString(_keyFor(email), jsonEncode(data.toJson()));
  }

  String _keyFor(String email) {
    return '$dataKeyPrefix:${email.trim().toLowerCase()}';
  }
}
