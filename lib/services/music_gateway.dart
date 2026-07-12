import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/youtube_api_config.dart';
import '../models/playlist.dart';
import '../models/song.dart';

abstract class MusicGateway {
  Future<List<Song>> getHomeTracks();
  Future<List<Song>> searchTracks(String keyword);
  Future<Song> resolveStream(Song song);
  Future<List<Playlist>> getPlaylists();
  void close();
}

class YoutubeMusicGateway implements MusicGateway {
  YoutubeMusicGateway({
    http.Client? httpClient,
    String apiKey = YoutubeApiConfig.apiKey,
  })  : _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null,
        _apiKey = apiKey;

  final http.Client _httpClient;
  final bool _ownsHttpClient;
  final String _apiKey;

  static const _timeout = Duration(seconds: 12);

  int get _resultLimit => kIsWeb ? 20 : 8;

  @override
  Future<List<Song>> getHomeTracks() {
    return searchTracks('vietnam music');
  }

  @override
  Future<List<Song>> searchTracks(String keyword) async {
    final query = keyword.trim();

    if (query.isEmpty) {
      return [];
    }

    final key = _apiKey.trim();

    if (key.isEmpty) {
      throw Exception('Missing YOUTUBE_API_KEY');
    }

    final searchJson = await _getJson(
      Uri.https('www.googleapis.com', '/youtube/v3/search', {
        'key': key,
        'part': 'snippet',
        'type': 'video',
        'videoCategoryId': '10',
        'videoEmbeddable': 'true',
        'maxResults': '$_resultLimit',
        'order': 'relevance',
        'regionCode': 'VN',
        'relevanceLanguage': 'vi',
        'safeSearch': 'moderate',
        'q': '$query music official audio MV',
      }),
    );

    final items = searchJson['items'];

    if (items is! List) {
      throw Exception('YouTube Data API returned no search items');
    }

    final songs = items
        .whereType<Map>()
        .map((item) => _songFromSearchItem(item.cast<String, dynamic>()))
        .whereType<Song>()
        .toList();

    if (songs.isEmpty) {
      return songs;
    }

    return _songsWithDurations(songs, key);
  }

  @override
  Future<Song> resolveStream(Song song) async {
    if (song.isYoutube) {
      final videoId = song.youtubeVideoId.trim();

      if (!_isYoutubeVideoId(videoId)) {
        throw Exception('Video YouTube khong hop le: $videoId');
      }

      return song.copyWith(
        streamUrl: 'youtube:$videoId',
        sourceType: 'youtube',
        sourceId: videoId,
      );
    }

    if (song.hasStream) {
      return song;
    }

    throw Exception('Bai hat chua co streamUrl');
  }

  @override
  Future<List<Playlist>> getPlaylists() async {
    return [];
  }

  @override
  void close() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _httpClient.get(
      uri,
      headers: const {'accept': 'application/json'},
    ).timeout(_timeout);
    final body = utf8.decode(response.bodyBytes);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_readApiError(response.statusCode, body));
    }

    final decoded = jsonDecode(body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('YouTube Data API returned invalid JSON');
    }

    return decoded;
  }

  Future<List<Song>> _songsWithDurations(
    List<Song> songs,
    String key,
  ) async {
    final ids = songs.map((song) => song.id).where((id) => id.isNotEmpty);
    final videosJson = await _getJson(
      Uri.https('www.googleapis.com', '/youtube/v3/videos', {
        'key': key,
        'part': 'contentDetails',
        'id': ids.join(','),
      }),
    );
    final items = videosJson['items'];

    if (items is! List) {
      return songs;
    }

    final durationsById = <String, Duration>{};

    for (final item in items.whereType<Map>()) {
      final id = '${item['id'] ?? ''}';
      final details = item['contentDetails'];
      final duration = details is Map
          ? _parseIso8601Duration('${details['duration'] ?? ''}')
          : Duration.zero;

      if (id.isNotEmpty && duration > Duration.zero) {
        durationsById[id] = duration;
      }
    }

    return songs.map((song) {
      return song.copyWith(duration: durationsById[song.id] ?? song.duration);
    }).toList();
  }

  Song? _songFromSearchItem(Map<String, dynamic> item) {
    final id = item['id'];
    final snippet = item['snippet'];

    if (id is! Map || snippet is! Map) {
      return null;
    }

    final videoId = '${id['videoId'] ?? ''}'.trim();

    if (!_isYoutubeVideoId(videoId)) {
      return null;
    }

    final thumbnails = snippet['thumbnails'];

    return Song(
      id: videoId,
      title: _decodeHtml('${snippet['title'] ?? 'Untitled'}'),
      artist: _decodeHtml('${snippet['channelTitle'] ?? 'YouTube'}'),
      coverUrl: thumbnails is Map
          ? _readThumbnailUrl(thumbnails.cast<String, dynamic>())
          : '',
      sourceType: 'youtube',
      sourceId: videoId,
    );
  }

  bool _isYoutubeVideoId(String value) {
    return RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(value);
  }

  String _readApiError(int statusCode, String body) {
    try {
      final decoded = jsonDecode(body);
      final error = decoded is Map ? decoded['error'] : null;
      final message = error is Map ? error['message'] : null;

      if (message != null) {
        return '$message';
      }
    } catch (_) {}

    return 'YouTube Data API HTTP $statusCode: $body';
  }

  String _readThumbnailUrl(Map<String, dynamic> thumbnails) {
    for (final key in ['maxres', 'standard', 'high', 'medium', 'default']) {
      final thumbnail = thumbnails[key];

      if (thumbnail is! Map) {
        continue;
      }

      final url = thumbnail['url'];

      if (url is String && url.trim().isNotEmpty) {
        return url;
      }
    }

    return '';
  }

  String _decodeHtml(String value) {
    return value
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }

  Duration _parseIso8601Duration(String value) {
    final match = RegExp(
      r'^P(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$',
    ).firstMatch(value);

    if (match == null) {
      return Duration.zero;
    }

    return Duration(
      days: int.tryParse(match.group(1) ?? '') ?? 0,
      hours: int.tryParse(match.group(2) ?? '') ?? 0,
      minutes: int.tryParse(match.group(3) ?? '') ?? 0,
      seconds: int.tryParse(match.group(4) ?? '') ?? 0,
    );
  }
}

final MusicGateway musicGateway = YoutubeMusicGateway();
