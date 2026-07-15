import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../models/models.dart';

class _CachedStreams {
  const _CachedStreams(this.urls, this.expires);

  final List<String> urls;
  final DateTime expires;
}

class MusicGateway {
  final YoutubeExplode _youtube = YoutubeExplode();
  final http.Client _http = http.Client();
  final Map<String, _CachedStreams> _cache = {};
  final Map<String, Future<List<Song>>> _pending = {};

  Future<List<Song>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final results = await _youtube.search
        .search(trimmed)
        .timeout(const Duration(seconds: 10));
    return results
        .take(24)
        .map(
          (video) => Song(
            id: video.id.value,
            title: video.title,
            artist: video.author,
            artworkUrl: video.thumbnails.highResUrl,
            durationMs: video.duration?.inMilliseconds ?? 0,
          ),
        )
        .toList(growable: false);
  }

  Future<List<String>> suggestions(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    try {
      final uri = Uri.https(
        'suggestqueries.google.com',
        '/complete/search',
        {
          'client': 'firefox',
          'ds': 'yt',
          'q': trimmed,
        },
      );
      final response = await _http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return [];
      final decoded = jsonDecode(response.body);
      if (decoded is! List || decoded.length < 2 || decoded[1] is! List) {
        return [];
      }
      return (decoded[1] as List)
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .take(8)
          .toList(growable: false);
    } catch (_) {
      return [];
    }
  }

  Future<List<Song>> resolveCandidates(Song song) {
    if (song.source == SongSource.local) return Future.value([song]);

    final cached = _cache[song.id];
    if (cached != null && cached.expires.isAfter(DateTime.now())) {
      return Future.value(
        cached.urls.map((url) => song.copyWith(streamUrl: url)).toList(),
      );
    }

    return _pending.putIfAbsent(
      song.id,
      () => _resolveCandidates(song).whenComplete(
        () => _pending.remove(song.id),
      ),
    );
  }

  Future<List<Song>> _resolveCandidates(Song song) async {
    final attempts = <Future<List<String>>>[
      _manifestUrls(
        song.id,
        clients: [YoutubeApiClient.ios, YoutubeApiClient.androidVr],
      ),
      Future<List<String>>.delayed(
        const Duration(milliseconds: 850),
        () => _manifestUrls(song.id),
      ),
    ];

    final urls = await _firstNonEmpty(attempts).timeout(
      const Duration(seconds: 11),
      onTimeout: () => const [],
    );

    if (urls.isEmpty) {
      throw Exception('Không tìm thấy luồng âm thanh phù hợp.');
    }

    _cache[song.id] = _CachedStreams(
      List.unmodifiable(urls),
      DateTime.now().add(const Duration(minutes: 35)),
    );
    return urls.map((url) => song.copyWith(streamUrl: url)).toList();
  }

  Future<List<String>> _manifestUrls(
    String videoId, {
    List<YoutubeApiClient>? clients,
  }) async {
    try {
      final manifest = clients == null
          ? await _youtube.videos.streams
              .getManifest(videoId)
              .timeout(const Duration(seconds: 8))
          : await _youtube.videos.streams
              .getManifest(videoId, ytClients: clients)
              .timeout(const Duration(seconds: 8));

      final audio = manifest.audioOnly.toList()
        ..sort(
          (a, b) => _score(a.bitrate.bitsPerSecond)
              .compareTo(_score(b.bitrate.bitsPerSecond)),
        );
      final urls = <String>[];
      final seen = <String>{};
      for (final stream in audio.take(3)) {
        final url = stream.url.toString();
        if (seen.add(url)) urls.add(url);
      }
      if (urls.isEmpty) {
        final muxed = manifest.muxed.toList()
          ..sort(
            (a, b) => a.bitrate.bitsPerSecond.compareTo(
              b.bitrate.bitsPerSecond,
            ),
          );
        for (final stream in muxed.take(1)) {
          final url = stream.url.toString();
          if (seen.add(url)) urls.add(url);
        }
      }
      return urls;
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> _firstNonEmpty(
    List<Future<List<String>>> futures,
  ) {
    final completer = Completer<List<String>>();
    var remaining = futures.length;

    for (final future in futures) {
      future.then(
        (value) {
          if (value.isNotEmpty && !completer.isCompleted) {
            completer.complete(value);
          }
        },
        onError: (Object _, StackTrace __) {},
      ).whenComplete(() {
        remaining -= 1;
        if (remaining == 0 && !completer.isCompleted) {
          completer.complete(const []);
        }
      });
    }
    return completer.future;
  }

  int _score(int bitrate) {
    const target = 128000;
    return (bitrate - target).abs();
  }

  Future<void> prefetch(Song? song) async {
    if (song == null || song.source == SongSource.local) return;
    try {
      await resolveCandidates(song);
    } catch (_) {
      // Prefetch is best-effort and must never block visible UI.
    }
  }

  Future<void> prefetchMany(
    Iterable<Song> songs, {
    int maxCount = 8,
  }) async {
    final list = songs
        .where((song) => song.source == SongSource.youtube)
        .take(maxCount)
        .toList(growable: false);
    var nextIndex = 0;

    Future<void> worker() async {
      while (nextIndex < list.length) {
        final index = nextIndex;
        nextIndex += 1;
        await prefetch(list[index]);
      }
    }

    await Future.wait([worker(), worker()]);
  }

  void invalidate(String songId) => _cache.remove(songId);

  void dispose() {
    _http.close();
    _youtube.close();
  }
}
