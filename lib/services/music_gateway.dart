import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Playlist;

import '../core/music_api_config.dart';
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
    YoutubeExplode? youtube,
    http.Client? httpClient,
    String? musicApiBaseUrl,
  })  : _yt = youtube ?? YoutubeExplode(),
        _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null,
        _musicApiBaseUrl = musicApiBaseUrl ?? MusicApiConfig.baseUrl;

  final YoutubeExplode _yt;
  final http.Client _httpClient;
  final bool _ownsHttpClient;
  final String _musicApiBaseUrl;
  static const _musicApiTimeout = Duration(seconds: 5);
  static const _youtubeSearchTimeout = Duration(seconds: 12);
  static const _youtubeStreamTimeout = Duration(seconds: 15);

  String get _effectiveMusicApiBaseUrl {
    final configured = _musicApiBaseUrl.trim();

    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        configured.startsWith('http://localhost')) {
      return configured.replaceFirst('http://localhost', 'http://10.0.2.2');
    }

    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        configured.startsWith('http://127.0.0.1')) {
      return configured.replaceFirst('http://127.0.0.1', 'http://10.0.2.2');
    }

    return configured;
  }

  bool get _usesMusicApi => _effectiveMusicApiBaseUrl.isNotEmpty;

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

    if (_usesMusicApi) {
      try {
        return await _searchTracksFromApi(query);
      } catch (_) {
        if (kIsWeb) {
          rethrow;
        }
      }
    }

    try {
      final videos = await _yt.search.search(query).timeout(
            _youtubeSearchTimeout,
          );

      return videos
          .where((video) => (video.duration?.inSeconds ?? 0) > 0)
          .take(_resultLimit)
          .map((video) {
        return Song(
          id: video.id.value,
          title: video.title,
          artist: video.author,
          coverUrl: video.thumbnails.highResUrl,
          duration: video.duration ?? Duration.zero,
        );
      }).toList();
    } catch (primaryError) {
      try {
        return await _searchTracksFromWeb(query);
      } catch (fallbackError) {
        throw Exception(
          'YouTube search failed: $primaryError; fallback failed: $fallbackError',
        );
      }
    }
  }

  @override
  Future<Song> resolveStream(Song song) async {
    if (song.hasStream) {
      return song;
    }

    if (_usesMusicApi) {
      try {
        return await _resolveStreamFromApi(song);
      } catch (_) {
        if (kIsWeb) {
          rethrow;
        }
      }
    }

    final manifest = await _yt.videos.streams
        .getManifest(
          song.id,
          ytClients: [
            YoutubeApiClient.ios,
            YoutubeApiClient.androidSdkless,
          ],
          requireWatchPage: false,
        )
        .timeout(_youtubeStreamTimeout);
    final streamUrl = _streamUrlFromManifest(manifest);

    if (streamUrl != null) {
      return song.copyWith(streamUrl: streamUrl);
    }

    throw Exception('Không lấy được stream cho bài này');
  }

  @override
  Future<List<Playlist>> getPlaylists() async {
    return [];
  }

  @override
  void close() {
    _yt.close();
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }

  Future<List<Song>> _searchTracksFromApi(String query) async {
    final json = await _getMusicApiJson(
      _musicApiUri('/api/search', {
        'q': query,
        'limit': '$_resultLimit',
      }),
    );
    final songs = json is Map ? json['songs'] : null;

    if (songs is! List) {
      throw Exception('Music API returned an invalid search payload');
    }

    return songs
        .whereType<Map>()
        .map((item) => Song.fromJson(item.cast<String, dynamic>()))
        .where((song) => song.id.isNotEmpty && song.title.isNotEmpty)
        .toList();
  }

  Future<Song> _resolveStreamFromApi(Song song) async {
    final json = await _getMusicApiJson(
      _musicApiUri('/api/resolve', {'id': song.id}),
    );

    if (json is! Map) {
      throw Exception('Music API returned an invalid stream payload');
    }

    final streamUrl = '${json['streamUrl'] ?? ''}'.trim();

    if (streamUrl.isEmpty) {
      throw Exception('Music API did not return streamUrl');
    }

    return song.copyWith(streamUrl: streamUrl);
  }

  Future<dynamic> _getMusicApiJson(Uri uri) async {
    late http.Response response;

    try {
      response = await _httpClient.get(
        uri,
        headers: const {'accept': 'application/json'},
      ).timeout(_musicApiTimeout);
    } catch (error) {
      throw Exception(
        'Music API proxy is not reachable at $_effectiveMusicApiBaseUrl. '
        'Run: dart run bin/music_proxy.dart. $error',
      );
    }

    final body = utf8.decode(response.bodyBytes);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Music API HTTP ${response.statusCode}: $body');
    }

    return jsonDecode(body);
  }

  Uri _musicApiUri(String path, Map<String, String> queryParameters) {
    final base = Uri.parse(_effectiveMusicApiBaseUrl);
    final basePath = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;

    return base.replace(
      path: '$basePath$path',
      queryParameters: {
        ...base.queryParameters,
        ...queryParameters,
      },
    );
  }

  Future<List<Song>> _searchTracksFromWeb(String query) async {
    final uri = Uri.https('www.youtube.com', '/results', {
      'search_query': query,
    });
    final response = await _httpClient.get(
      uri,
      headers: const {
        'user-agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'accept-language': 'en-US,en;q=0.9',
      },
    ).timeout(_youtubeSearchTimeout);

    if (response.statusCode != 200) {
      throw Exception('YouTube returned HTTP ${response.statusCode}');
    }

    final initialData = _extractInitialData(utf8.decode(response.bodyBytes));
    final renderers = <Map<String, dynamic>>[];
    _collectVideoRenderers(initialData, renderers);

    final seenIds = <String>{};
    final songs = <Song>[];

    for (final renderer in renderers) {
      final song = _songFromRenderer(renderer);

      if (song == null || !seenIds.add(song.id)) {
        continue;
      }

      songs.add(song);

      if (songs.length >= _resultLimit) {
        break;
      }
    }

    if (songs.isEmpty) {
      throw Exception('No YouTube video results found');
    }

    return songs;
  }

  Map<String, dynamic> _extractInitialData(String html) {
    const markers = [
      'var ytInitialData =',
      'window["ytInitialData"] =',
      'ytInitialData =',
    ];

    for (final marker in markers) {
      final markerIndex = html.indexOf(marker);

      if (markerIndex < 0) {
        continue;
      }

      final jsonStart = html.indexOf('{', markerIndex + marker.length);

      if (jsonStart < 0) {
        continue;
      }

      final jsonEnd = _findJsonObjectEnd(html, jsonStart);
      final decoded = jsonDecode(html.substring(jsonStart, jsonEnd + 1));

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }

    throw const FormatException('ytInitialData not found');
  }

  int _findJsonObjectEnd(String source, int start) {
    var depth = 0;
    var inString = false;
    var escaping = false;

    for (var i = start; i < source.length; i++) {
      final code = source.codeUnitAt(i);

      if (inString) {
        if (escaping) {
          escaping = false;
        } else if (code == 0x5C) {
          escaping = true;
        } else if (code == 0x22) {
          inString = false;
        }

        continue;
      }

      if (code == 0x22) {
        inString = true;
      } else if (code == 0x7B) {
        depth++;
      } else if (code == 0x7D) {
        depth--;

        if (depth == 0) {
          return i;
        }
      }
    }

    throw const FormatException('Unclosed ytInitialData object');
  }

  void _collectVideoRenderers(
      dynamic value, List<Map<String, dynamic>> output) {
    if (output.length >= 80) {
      return;
    }

    if (value is Map) {
      final renderer = value['videoRenderer'];

      if (renderer is Map) {
        output.add(renderer.cast<String, dynamic>());
      }

      for (final child in value.values) {
        _collectVideoRenderers(child, output);
      }
    } else if (value is List) {
      for (final child in value) {
        _collectVideoRenderers(child, output);
      }
    }
  }

  Song? _songFromRenderer(Map<String, dynamic> renderer) {
    final id = _readString(renderer['videoId']);
    final title = _readText(renderer['title']);

    if (id == null || id.isEmpty || title == null || title.isEmpty) {
      return null;
    }

    final artist = _readText(renderer['ownerText']) ??
        _readText(renderer['longBylineText']) ??
        _readText(renderer['shortBylineText']) ??
        '';

    final duration = _parseDuration(_readText(renderer['lengthText']));

    if (duration == Duration.zero) {
      return null;
    }

    return Song(
      id: id,
      title: title,
      artist: artist,
      coverUrl: _readThumbnailUrl(renderer['thumbnail']),
      duration: duration,
    );
  }

  String? _streamUrlFromManifest(StreamManifest manifest) {
    if (manifest.audioOnly.isNotEmpty) {
      return (_bestMp4Stream(manifest.audioOnly) ??
              _bestStream(manifest.audioOnly))
          .url
          .toString();
    }

    if (manifest.audio.isNotEmpty) {
      return (_bestMp4Stream(manifest.audio) ?? _bestStream(manifest.audio))
          .url
          .toString();
    }

    if (manifest.muxed.isNotEmpty) {
      return (_bestMp4Stream(manifest.muxed) ?? _bestStream(manifest.muxed))
          .url
          .toString();
    }

    if (manifest.hls.isNotEmpty) {
      return manifest.hls.first.url.toString();
    }

    return null;
  }

  T? _bestMp4Stream<T extends StreamInfo>(Iterable<T> streams) {
    final mp4Streams = streams.where((stream) {
      return stream.container.name.toLowerCase() == 'mp4';
    }).toList();

    if (mp4Streams.isEmpty) {
      return null;
    }

    return _bestStream(mp4Streams);
  }

  T _bestStream<T extends StreamInfo>(Iterable<T> streams) {
    final byBitrate = streams.sortByBitrate();

    for (final stream in byBitrate) {
      if (stream.url.queryParameters['c'] == 'IOS') {
        return stream;
      }
    }

    return byBitrate.first;
  }

  String? _readString(dynamic value) {
    return value is String ? value : null;
  }

  String? _readText(dynamic value) {
    if (value is String) {
      return value;
    }

    if (value is! Map) {
      return null;
    }

    final simpleText = value['simpleText'];

    if (simpleText is String) {
      return simpleText;
    }

    final runs = value['runs'];

    if (runs is! List) {
      return null;
    }

    final buffer = StringBuffer();

    for (final run in runs) {
      if (run is! Map) {
        continue;
      }

      final text = run['text'];

      if (text is String) {
        buffer.write(text);
      }
    }

    final text = buffer.toString().trim();
    return text.isEmpty ? null : text;
  }

  String _readThumbnailUrl(dynamic value) {
    if (value is! Map) {
      return '';
    }

    final thumbnails = value['thumbnails'];

    if (thumbnails is! List || thumbnails.isEmpty) {
      return '';
    }

    final last = thumbnails.last;

    if (last is! Map) {
      return '';
    }

    return _readString(last['url']) ?? '';
  }

  Duration _parseDuration(String? value) {
    if (value == null || value.isEmpty) {
      return Duration.zero;
    }

    final parts = value.split(':').map(int.tryParse).toList();

    if (parts.any((part) => part == null)) {
      return Duration.zero;
    }

    var seconds = 0;

    for (final part in parts) {
      seconds = seconds * 60 + part!;
    }

    return Duration(seconds: seconds);
  }
}

final MusicGateway musicGateway = YoutubeMusicGateway();
