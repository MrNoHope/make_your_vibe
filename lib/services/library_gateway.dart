import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/music_api_config.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import 'supabase_gateway.dart';

class LibraryGatewayException implements Exception {
  final String message;

  const LibraryGatewayException(this.message);

  @override
  String toString() => message;
}

class UploadedSongInput {
  final String title;
  final String artist;
  final String fileName;
  final Uint8List audioBytes;
  final String albumId;
  final String albumTitle;
  final Uint8List? coverBytes;
  final String? coverName;
  final Duration duration;

  const UploadedSongInput({
    required this.title,
    required this.artist,
    required this.fileName,
    required this.audioBytes,
    this.albumId = '',
    this.albumTitle = '',
    this.coverBytes,
    this.coverName,
    this.duration = Duration.zero,
  });
}

class LibraryGateway {
  LibraryGateway({
    SupabaseGateway? supabase,
    FirebaseAuth? firebaseAuth,
  })  : _supabase = supabase ?? supabaseGateway,
        _firebaseAuth = firebaseAuth;

  static const songsBucket = 'songs';
  static const coversBucket = 'covers';
  static const signedUrlTtlSeconds = 21600;
  static const _youtubeAudioPrefix = 'youtube:';
  static const _externalCoverPrefix = 'external:';

  final SupabaseGateway _supabase;
  final FirebaseAuth? _firebaseAuth;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;

  bool get isConfigured => _supabase.isConfigured;

  Future<List<Playlist>> getAlbums() async {
    final client = await _supabase.requireClient();
    final ownerId = _currentOwnerId();
    final rows = await client
        .from('albums')
        .select()
        .eq('owner_id', ownerId)
        .order('created_at');

    final playlists = <Playlist>[];
    for (final row in _asRows(rows)) {
      playlists.add(await _playlistFromRow(client, row));
    }
    return playlists;
  }

  Future<Playlist> getAlbum(String albumId) async {
    final client = await _supabase.requireClient();
    final row = _asRow(
      await client.from('albums').select().eq('id', albumId).single(),
    );
    final relationRows = await client
        .from('album_songs')
        .select('position,songs(*)')
        .eq('album_id', albumId)
        .order('position', ascending: true);

    final songs = <Song>[];
    for (final relationRow in _asRows(relationRows)) {
      final songRow = relationRow['songs'];
      if (songRow is Map) {
        songs.add(await _songFromRow(client, _asRow(songRow)));
      }
    }

    return _playlistFromRowSync(
      row,
      coverUrl: await _signedCoverUrl(client, row['cover_path']),
      songs: songs,
    );
  }

  Future<List<Song>> getSongs() async {
    final client = await _supabase.requireClient();
    final ownerId = _currentOwnerId();
    final rows = await client
        .from('songs')
        .select()
        .eq('owner_id', ownerId)
        .order('created_at');

    final songs = <Song>[];
    for (final row in _asRows(rows)) {
      songs.add(await _songFromRow(client, row));
    }
    return songs;
  }

  Future<Playlist> createAlbum({
    required String title,
    String subtitle = '',
    Uint8List? coverBytes,
    String? coverName,
  }) async {
    final client = await _supabase.requireClient();
    final ownerId = _currentOwnerId();
    final cleanTitle = title.trim();

    if (cleanTitle.isEmpty) {
      throw const LibraryGatewayException('Album title is required.');
    }

    final coverPath = coverBytes == null
        ? ''
        : await _uploadBinary(
            client: client,
            bucket: coversBucket,
            ownerId: ownerId,
            folder: 'albums',
            fileName: coverName ?? 'cover.jpg',
            bytes: coverBytes,
          );

    final row = _asRow(
      await client
          .from('albums')
          .insert({
            'owner_id': ownerId,
            'title': cleanTitle,
            'subtitle': subtitle.trim(),
            'cover_path': coverPath,
          })
          .select()
          .single(),
    );

    return _playlistFromRow(
      client,
      row,
    );
  }

  Future<Song> uploadSong(UploadedSongInput input) async {
    final client = await _supabase.requireClient();
    final ownerId = _currentOwnerId();
    final cleanTitle = input.title.trim();

    if (cleanTitle.isEmpty) {
      throw const LibraryGatewayException('Song title is required.');
    }

    if (input.audioBytes.isEmpty) {
      throw const LibraryGatewayException('Audio file is empty.');
    }

    final audioPath = await _uploadBinary(
      client: client,
      bucket: songsBucket,
      ownerId: ownerId,
      folder: 'audio',
      fileName: input.fileName,
      bytes: input.audioBytes,
    );
    final coverPath = input.coverBytes == null
        ? ''
        : await _uploadBinary(
            client: client,
            bucket: coversBucket,
            ownerId: ownerId,
            folder: 'songs',
            fileName: input.coverName ?? 'cover.jpg',
            bytes: input.coverBytes!,
          );

    final row = _asRow(
      await client
          .from('songs')
          .insert({
            'owner_id': ownerId,
            'title': cleanTitle,
            'artist': input.artist.trim(),
            'album': input.albumTitle.trim(),
            'duration_seconds': input.duration.inSeconds,
            'audio_path': audioPath,
            'cover_path': coverPath,
          })
          .select()
          .single(),
    );

    if (input.albumId.trim().isNotEmpty) {
      await _linkSongToAlbum(
        client,
        albumId: input.albumId,
        songId: _string(row['id']),
      );
    }

    return _songFromRow(client, row);
  }

  Future<void> addSongToAlbum({
    required String songId,
    required String albumId,
  }) async {
    final client = await _supabase.requireClient();
    await _linkSongToAlbum(client, albumId: albumId, songId: songId);
  }

  Future<Song> saveOnlineSongToAlbum({
    required Song song,
    required String albumId,
    String albumTitle = '',
  }) async {
    final client = await _supabase.requireClient();
    final ownerId = _currentOwnerId();
    final cleanAlbumId = albumId.trim();
    final sourceId = song.id.trim();

    if (cleanAlbumId.isEmpty) {
      throw const LibraryGatewayException('Album is required.');
    }
    if (sourceId.isEmpty) {
      throw const LibraryGatewayException('Song id is required.');
    }

    final audioPath = '$_youtubeAudioPrefix$sourceId';
    final existingRows = _asRows(
      await client
          .from('songs')
          .select()
          .eq('owner_id', ownerId)
          .eq('audio_path', audioPath)
          .limit(1),
    );

    final row = existingRows.isNotEmpty
        ? existingRows.first
        : _asRow(
            await client
                .from('songs')
                .insert({
                  'owner_id': ownerId,
                  'title': song.title.trim().isEmpty
                      ? 'Untitled song'
                      : song.title.trim(),
                  'artist': song.artist.trim(),
                  'album': albumTitle.trim(),
                  'duration_seconds': song.duration.inSeconds,
                  'audio_path': audioPath,
                  'cover_path': song.coverUrl.trim().isEmpty
                      ? ''
                      : '$_externalCoverPrefix${song.coverUrl.trim()}',
                })
                .select()
                .single(),
          );

    await _linkSongToAlbum(
      client,
      albumId: cleanAlbumId,
      songId: _string(row['id']),
    );

    return _songFromRow(client, row);
  }

  Future<void> _linkSongToAlbum(
    SupabaseClient client, {
    required String albumId,
    required String songId,
  }) async {
    final cleanAlbumId = albumId.trim();
    final cleanSongId = songId.trim();

    if (cleanAlbumId.isEmpty || cleanSongId.isEmpty) {
      return;
    }

    final existingRows = _asRows(
      await client
          .from('album_songs')
          .select('song_id')
          .eq('album_id', cleanAlbumId)
          .eq('song_id', cleanSongId)
          .limit(1),
    );

    if (existingRows.isNotEmpty) {
      return;
    }

    await client.from('album_songs').insert({
      'album_id': cleanAlbumId,
      'song_id': cleanSongId,
      'position': await _nextAlbumPosition(client, cleanAlbumId),
    });
  }

  Future<int> _nextAlbumPosition(SupabaseClient client, String albumId) async {
    final rows = await client
        .from('album_songs')
        .select('song_id')
        .eq('album_id', albumId);
    return _asRows(rows).length;
  }

  Future<String> _uploadBinary({
    required SupabaseClient client,
    required String bucket,
    required String ownerId,
    required String folder,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final objectPath = _storagePath(ownerId, folder, fileName);
    final contentType = lookupMimeType(fileName, headerBytes: bytes) ??
        'application/octet-stream';

    await client.storage.from(bucket).uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: false,
          ),
        );

    return objectPath;
  }

  Future<Playlist> _playlistFromRow(
    SupabaseClient client,
    Map<String, dynamic> row, {
    List<Song> songs = const [],
  }) async {
    return _playlistFromRowSync(
      row,
      coverUrl: await _signedCoverUrl(client, row['cover_path']),
      songs: songs,
    );
  }

  Playlist _playlistFromRowSync(
    Map<String, dynamic> row, {
    required String coverUrl,
    List<Song> songs = const [],
  }) {
    return Playlist(
      id: _string(row['id']),
      title: _string(row['title']),
      subtitle: _string(row['subtitle']),
      coverUrl: coverUrl,
      songs: songs,
    );
  }

  Future<Song> _songFromRow(
    SupabaseClient client,
    Map<String, dynamic> row,
  ) async {
    final audioPath = _string(row['audio_path']);
    final coverPath = _string(row['cover_path']);

    return Song(
      id: _string(row['id']),
      title: _string(row['title']),
      artist: _string(row['artist']),
      album: _string(row['album']),
      coverUrl: await _signedCoverUrl(client, coverPath),
      duration: Duration(seconds: _int(row['duration_seconds'])),
      streamUrl: await _streamUrlForAudioPath(client, audioPath),
    );
  }

  Future<String> _signedCoverUrl(
      SupabaseClient client, dynamic coverPath) async {
    final cleanPath = _string(coverPath);
    if (cleanPath.isEmpty) {
      return '';
    }
    if (cleanPath.startsWith(_externalCoverPrefix)) {
      return cleanPath.substring(_externalCoverPrefix.length);
    }
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return cleanPath;
    }

    try {
      return await client.storage
          .from(coversBucket)
          .createSignedUrl(cleanPath, signedUrlTtlSeconds);
    } catch (_) {
      return '';
    }
  }

  Future<String> _streamUrlForAudioPath(
    SupabaseClient client,
    String audioPath,
  ) async {
    final cleanPath = audioPath.trim();

    if (cleanPath.isEmpty) {
      return '';
    }

    if (cleanPath.startsWith(_youtubeAudioPrefix)) {
      final sourceId = cleanPath.substring(_youtubeAudioPrefix.length);
      return _musicApiUri('/api/stream', {'id': sourceId}).toString();
    }

    return client.storage
        .from(songsBucket)
        .createSignedUrl(cleanPath, signedUrlTtlSeconds);
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

  String get _effectiveMusicApiBaseUrl {
    final configured = MusicApiConfig.baseUrl.trim();

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

  String _currentOwnerId() {
    final user = _auth.currentUser;

    if (user == null) {
      throw const LibraryGatewayException('Login required.');
    }

    return user.uid;
  }

  String _storagePath(String ownerId, String folder, String fileName) {
    final stamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    final safeName = _safeFileName(fileName);
    return 'users/$ownerId/$folder/${stamp}_$safeName';
  }

  String _safeFileName(String fileName) {
    final baseName = path.basename(fileName).trim();
    final safeName = baseName.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    return safeName.isEmpty ? 'file' : safeName;
  }

  List<Map<String, dynamic>> _asRows(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value.whereType<Map>().map(_asRow).toList();
  }

  Map<String, dynamic> _asRow(dynamic value) {
    return Map<String, dynamic>.from(value as Map);
  }

  String _string(dynamic value) => value == null ? '' : '$value';

  int _int(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

final libraryGateway = LibraryGateway();
