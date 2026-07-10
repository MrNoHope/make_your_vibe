import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Playlist;

final _streamCache = <String, StreamInfo>{};

Future<void> main(List<String> args) async {
  final port = _readPort(args);
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  final yt = YoutubeExplode();

  void shutdown(ProcessSignal signal) {
    yt.close();
    unawaited(server.close(force: true));
    exit(0);
  }

  ProcessSignal.sigint.watch().listen(shutdown);
  if (!Platform.isWindows) {
    ProcessSignal.sigterm.watch().listen(shutdown);
  }

  stdout.writeln('Music API proxy running at http://localhost:$port');
  stdout.writeln('Health: http://localhost:$port/health');

  await for (final request in server) {
    unawaited(_handleRequest(request, yt));
  }
}

int _readPort(List<String> args) {
  final envPort = int.tryParse(Platform.environment['MUSIC_API_PORT'] ?? '');

  if (envPort != null) {
    return envPort;
  }

  final index = args.indexOf('--port');

  if (index >= 0 && index + 1 < args.length) {
    return int.tryParse(args[index + 1]) ?? 8765;
  }

  return 8765;
}

Future<void> _handleRequest(HttpRequest request, YoutubeExplode yt) async {
  _setCors(request.response);

  if (request.method == 'OPTIONS') {
    request.response.statusCode = HttpStatus.noContent;
    await request.response.close();
    return;
  }

  try {
    final path = request.uri.path;

    if (path == '/health') {
      await _sendJson(request, {'ok': true});
      return;
    }

    if (path == '/api/search') {
      await _handleSearch(request, yt);
      return;
    }

    if (path == '/api/resolve') {
      await _handleResolve(request, yt);
      return;
    }

    if (path == '/api/stream') {
      await _handleStream(request, yt);
      return;
    }

    await _sendJson(
      request,
      {'error': 'Not found'},
      statusCode: HttpStatus.notFound,
    );
  } catch (error, stackTrace) {
    stderr.writeln(error);
    stderr.writeln(stackTrace);
    await _sendJson(
      request,
      {'error': '$error'},
      statusCode: HttpStatus.internalServerError,
    );
  }
}

Future<void> _handleSearch(HttpRequest request, YoutubeExplode yt) async {
  final query = request.uri.queryParameters['q']?.trim() ?? '';
  final limit = int.tryParse(request.uri.queryParameters['limit'] ?? '') ?? 20;

  if (query.isEmpty) {
    await _sendJson(request, {'songs': <Object>[]});
    return;
  }

  final songs = await _searchSongs(yt, query, limit.clamp(1, 40));

  await _sendJson(request, {'songs': songs});
}

Future<List<Map<String, Object>>> _searchSongs(
  YoutubeExplode yt,
  String query,
  int limit,
) async {
  try {
    final videos = await yt.search.search(query);
    return videos
        .where((video) => (video.duration?.inSeconds ?? 0) > 0)
        .take(limit)
        .map((video) {
      return {
        'id': video.id.value,
        'title': video.title,
        'artist': video.author,
        'coverUrl': video.thumbnails.highResUrl,
        'durationSeconds': (video.duration ?? Duration.zero).inSeconds,
      };
    }).toList();
  } catch (_) {
    return _searchSongsFromWeb(query, limit);
  }
}

Future<List<Map<String, Object>>> _searchSongsFromWeb(
  String query,
  int limit,
) async {
  final uri = Uri.https('www.youtube.com', '/results', {
    'search_query': query,
  });
  final response = await http.get(
    uri,
    headers: const {
      'user-agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'accept-language': 'en-US,en;q=0.9',
    },
  );

  if (response.statusCode != HttpStatus.ok) {
    throw Exception('YouTube returned HTTP ${response.statusCode}');
  }

  final initialData = _extractInitialData(utf8.decode(response.bodyBytes));
  final renderers = <Map<String, dynamic>>[];
  _collectVideoRenderers(initialData, renderers);

  final seenIds = <String>{};
  final songs = <Map<String, Object>>[];

  for (final renderer in renderers) {
    final song = _songFromRenderer(renderer);

    if (song == null || !seenIds.add('${song['id']}')) {
      continue;
    }

    songs.add(song);

    if (songs.length >= limit) {
      break;
    }
  }

  if (songs.isEmpty) {
    throw Exception('No YouTube video results found');
  }

  return songs;
}

Future<void> _handleResolve(HttpRequest request, YoutubeExplode yt) async {
  final id = request.uri.queryParameters['id']?.trim() ?? '';

  if (id.isEmpty) {
    await _sendJson(
      request,
      {'error': 'Missing id'},
      statusCode: HttpStatus.badRequest,
    );
    return;
  }

  final manifest = await yt.videos.streams.getManifest(
    id,
    ytClients: [
      YoutubeApiClient.ios,
      YoutubeApiClient.androidSdkless,
    ],
    requireWatchPage: false,
  );
  final streamInfo = _streamInfoFromManifest(manifest);

  if (streamInfo == null) {
    await _sendJson(
      request,
      {'error': 'No playable stream found'},
      statusCode: HttpStatus.notFound,
    );
    return;
  }

  _streamCache[id] = streamInfo;

  await _sendJson(request, {
    'id': id,
    'streamUrl': _streamUriForRequest(request, id).toString(),
  });
}

Future<void> _handleStream(HttpRequest request, YoutubeExplode yt) async {
  final id = request.uri.queryParameters['id']?.trim() ?? '';

  if (id.isEmpty) {
    await _sendJson(
      request,
      {'error': 'Missing id'},
      statusCode: HttpStatus.badRequest,
    );
    return;
  }

  final streamInfo = _streamCache[id] ??
      _streamInfoFromManifest(
        await yt.videos.streams.getManifest(
          id,
          ytClients: [
            YoutubeApiClient.ios,
            YoutubeApiClient.androidSdkless,
          ],
          requireWatchPage: false,
        ),
      );

  if (streamInfo == null) {
    request.response.statusCode = HttpStatus.notFound;
    request.response.write('No playable stream found');
    await request.response.close();
    return;
  }

  try {
    await _proxyStream(request, streamInfo);
  } catch (error, stackTrace) {
    stderr.writeln(error);
    stderr.writeln(stackTrace);
    try {
      await request.response.close();
    } catch (_) {}
  }
}

Future<void> _proxyStream(HttpRequest request, StreamInfo streamInfo) async {
  final client = http.Client();
  final requestedRange = _requestedRange(request, streamInfo);

  if (request.method == 'HEAD') {
    request.response.statusCode = HttpStatus.ok;
    request.response.headers
      ..set(HttpHeaders.contentTypeHeader, _contentTypeFor(streamInfo))
      ..set(HttpHeaders.cacheControlHeader, 'no-store')
      ..set(HttpHeaders.acceptRangesHeader, 'bytes')
      ..set(HttpHeaders.contentLengthHeader, streamInfo.size.totalBytes);
    await request.response.close();
    client.close();
    return;
  }

  final upstreamRequest = http.Request('GET', streamInfo.url);

  upstreamRequest.headers.addAll({
    HttpHeaders.userAgentHeader:
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    HttpHeaders.acceptHeader: '*/*',
    HttpHeaders.rangeHeader: requestedRange.headerValue,
  });

  try {
    final upstream = await client.send(upstreamRequest);
    final response = request.response;

    response.statusCode = upstream.statusCode;
    response.headers
      ..set(
          HttpHeaders.contentTypeHeader,
          upstream.headers[HttpHeaders.contentTypeHeader] ??
              _contentTypeFor(streamInfo))
      ..set(HttpHeaders.cacheControlHeader, 'no-store')
      ..set(HttpHeaders.acceptRangesHeader,
          upstream.headers[HttpHeaders.acceptRangesHeader] ?? 'bytes');

    final contentLength = upstream.headers[HttpHeaders.contentLengthHeader];
    final contentRange = upstream.headers[HttpHeaders.contentRangeHeader];

    if (contentLength != null) {
      response.headers.set(HttpHeaders.contentLengthHeader, contentLength);
    }

    response.headers.set(
      HttpHeaders.contentRangeHeader,
      contentRange ?? requestedRange.contentRangeHeader,
    );

    await upstream.stream.pipe(response);
  } finally {
    client.close();
  }
}

_ByteRange _requestedRange(HttpRequest request, StreamInfo streamInfo) {
  const chunkSize = 1024 * 1024;
  final totalBytes = streamInfo.size.totalBytes;
  final rawRange = request.headers.value(HttpHeaders.rangeHeader);
  var start = 0;
  int? end;

  if (rawRange != null && rawRange.startsWith('bytes=')) {
    final parts = rawRange.substring(6).split('-');

    if (parts.isNotEmpty && parts.first.isNotEmpty) {
      start = int.tryParse(parts.first) ?? 0;
    }

    if (parts.length > 1 && parts[1].isNotEmpty) {
      end = int.tryParse(parts[1]);
    }
  }

  if (totalBytes > 0 && start >= totalBytes) {
    start = totalBytes - 1;
  }

  final maxEnd = totalBytes <= 0 ? start + chunkSize - 1 : totalBytes - 1;
  final chunkEnd = (start + chunkSize - 1).clamp(start, maxEnd);
  final safeEnd = end == null ? chunkEnd : end.clamp(start, chunkEnd);

  return _ByteRange(
    start: start,
    end: safeEnd,
    totalBytes: totalBytes,
  );
}

class _ByteRange {
  const _ByteRange({
    required this.start,
    required this.end,
    required this.totalBytes,
  });

  final int start;
  final int end;
  final int totalBytes;

  String get headerValue => 'bytes=$start-$end';

  String get contentRangeHeader {
    final total = totalBytes <= 0 ? '*' : '$totalBytes';
    return 'bytes $start-$end/$total';
  }
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

void _collectVideoRenderers(dynamic value, List<Map<String, dynamic>> output) {
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

Map<String, Object>? _songFromRenderer(Map<String, dynamic> renderer) {
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

  if (duration == 0) {
    return null;
  }

  return {
    'id': id,
    'title': title,
    'artist': artist,
    'coverUrl': _readThumbnailUrl(renderer['thumbnail']),
    'durationSeconds': duration,
  };
}

StreamInfo? _streamInfoFromManifest(StreamManifest manifest) {
  if (manifest.audioOnly.isNotEmpty) {
    return _bestMp4Stream(manifest.audioOnly) ??
        _bestStream(manifest.audioOnly);
  }

  if (manifest.audio.isNotEmpty) {
    return _bestMp4Stream(manifest.audio) ?? _bestStream(manifest.audio);
  }

  if (manifest.muxed.isNotEmpty) {
    return _bestMp4Stream(manifest.muxed) ?? _bestStream(manifest.muxed);
  }

  if (manifest.hls.isNotEmpty) {
    return manifest.hls.first;
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

Uri _streamUriForRequest(HttpRequest request, String id) {
  final forwardedProto = request.headers.value('x-forwarded-proto');
  final forwardedHost = request.headers.value('x-forwarded-host');
  final host = forwardedHost ??
      request.headers.value(HttpHeaders.hostHeader) ??
      'localhost:8765';

  return Uri.parse(
    '${forwardedProto ?? 'http'}://$host/api/stream'
    '?id=${Uri.encodeQueryComponent(id)}',
  );
}

String _contentTypeFor(StreamInfo streamInfo) {
  final container = streamInfo.container.name.toLowerCase();

  if (container == 'webm') {
    return 'audio/webm';
  }

  if (container == 'mp3') {
    return 'audio/mpeg';
  }

  if (container == 'm3u8') {
    return 'application/vnd.apple.mpegurl';
  }

  return 'audio/mp4';
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

int _parseDuration(String? value) {
  if (value == null || value.isEmpty) {
    return 0;
  }

  final parts = value.split(':').map(int.tryParse).toList();

  if (parts.any((part) => part == null)) {
    return 0;
  }

  var seconds = 0;

  for (final part in parts) {
    seconds = seconds * 60 + part!;
  }

  return seconds;
}

Future<void> _sendJson(
  HttpRequest request,
  Object body, {
  int statusCode = HttpStatus.ok,
}) async {
  request.response.statusCode = statusCode;
  request.response.headers.contentType = ContentType.json;
  request.response.write(jsonEncode(body));
  await request.response.close();
}

void _setCors(HttpResponse response) {
  response.headers
    ..set('Access-Control-Allow-Origin', '*')
    ..set('Access-Control-Allow-Methods', 'GET, OPTIONS')
    ..set('Access-Control-Allow-Headers', 'content-type, authorization');
}
