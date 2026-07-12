import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart' show StorageException;

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
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    SupabaseGateway? supabase,
  })  : _firebaseAuth = firebaseAuth,
        _firestoreOverride = firestore,
        _supabaseOverride = supabase;

  static const _youtubeAudioPrefix = 'youtube:';
  static const _youtubeDocPrefix = 'youtube_';
  static const _sourceYoutube = 'youtube';
  static const _sourceUpload = 'upload';
  static const _serverGet = GetOptions(source: Source.server);

  final FirebaseAuth? _firebaseAuth;
  final FirebaseFirestore? _firestoreOverride;
  final SupabaseGateway? _supabaseOverride;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  SupabaseGateway get _supabase => _supabaseOverride ?? supabaseGateway;

  bool get isConfigured => Firebase.apps.isNotEmpty;

  Future<List<Playlist>> getAlbums() async {
    final user = _requireUser();
    final snapshot = await _firebaseRequest(
      _albumsRef(user.uid)
          .orderBy('createdAt', descending: true)
          .get(_serverGet),
    );

    return snapshot.docs.map(_playlistFromDoc).toList();
  }

  Future<Playlist> getAlbum(String albumId) async {
    final user = _requireUser();
    final cleanAlbumId = albumId.trim();

    if (cleanAlbumId.isEmpty) {
      throw const LibraryGatewayException('Album is required.');
    }

    final albumDoc = await _firebaseRequest(
      _albumsRef(user.uid).doc(cleanAlbumId).get(_serverGet),
    );
    if (!albumDoc.exists) {
      throw const LibraryGatewayException('Album not found.');
    }

    final itemSnapshot = await _firebaseRequest(
      _albumItemsRef(user.uid, cleanAlbumId).orderBy('position').get(
            _serverGet,
          ),
    );
    final songs = <Song>[];

    for (final itemDoc in itemSnapshot.docs) {
      final songId = _string(itemDoc.data()['songId']).trim();
      if (songId.isEmpty) {
        continue;
      }

      final songDoc = await _firebaseRequest(
        _songsRef(user.uid).doc(songId).get(_serverGet),
      );
      if (songDoc.exists) {
        songs.add(_songFromDoc(songDoc));
      }
    }

    final album = _playlistFromDoc(albumDoc);
    return Playlist(
      id: album.id,
      title: album.title,
      subtitle: album.subtitle,
      coverUrl: album.coverUrl,
      songs: songs,
    );
  }

  Future<List<Song>> getSongs() async {
    final user = _requireUser();
    final snapshot = await _firebaseRequest(
      _songsRef(user.uid).orderBy('createdAt', descending: true).get(
            _serverGet,
          ),
    );

    return snapshot.docs.map(_songFromDoc).toList();
  }

  Future<Playlist> createAlbum({
    required String title,
    String subtitle = '',
    Uint8List? coverBytes,
    String? coverName,
  }) async {
    final user = _requireUser();
    final cleanTitle = title.trim();

    if (cleanTitle.isEmpty) {
      throw const LibraryGatewayException('Album title is required.');
    }

    final cover = coverBytes == null
        ? const _UploadedFile()
        : await _uploadBinary(
            ownerId: user.uid,
            folder: 'covers/albums',
            fileName: coverName ?? 'cover.jpg',
            bytes: coverBytes,
          );

    final docRef = await _firebaseRequest(
      _albumsRef(user.uid).add({
        'ownerId': user.uid,
        'title': cleanTitle,
        'subtitle': subtitle.trim(),
        'coverUrl': cover.url,
        'coverPath': cover.path,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }),
    );

    return Playlist(
      id: docRef.id,
      title: cleanTitle,
      subtitle: subtitle.trim(),
      coverUrl: cover.url,
    );
  }

  Future<Song> uploadSong(UploadedSongInput input) async {
    final user = _requireUser();
    final cleanTitle = input.title.trim();

    if (cleanTitle.isEmpty) {
      throw const LibraryGatewayException('Song title is required.');
    }

    if (input.audioBytes.isEmpty) {
      throw const LibraryGatewayException('Audio file is empty.');
    }

    final audio = await _uploadBinary(
      ownerId: user.uid,
      folder: 'audio',
      fileName: input.fileName,
      bytes: input.audioBytes,
    );
    final cover = input.coverBytes == null
        ? const _UploadedFile()
        : await _uploadBinary(
            ownerId: user.uid,
            folder: 'covers/songs',
            fileName: input.coverName ?? 'cover.jpg',
            bytes: input.coverBytes!,
          );

    final docRef = await _firebaseRequest(
      _songsRef(user.uid).add({
        'ownerId': user.uid,
        'title': cleanTitle,
        'artist': input.artist.trim(),
        'album': input.albumTitle.trim(),
        'durationSeconds': input.duration.inSeconds,
        'streamUrl': audio.url,
        'audioPath': audio.path,
        'coverUrl': cover.url,
        'coverPath': cover.path,
        'sourceType': _sourceUpload,
        'sourceId': audio.path,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }),
    );

    if (input.albumId.trim().isNotEmpty) {
      await _linkSongToAlbum(
        ownerId: user.uid,
        albumId: input.albumId,
        songId: docRef.id,
      );
    }

    return Song(
      id: docRef.id,
      title: cleanTitle,
      artist: input.artist.trim(),
      album: input.albumTitle.trim(),
      coverUrl: cover.url,
      duration: input.duration,
      streamUrl: audio.url,
      databaseId: docRef.id,
      sourceType: _sourceUpload,
      sourceId: audio.path,
    );
  }

  Future<void> addSongToAlbum({
    required String songId,
    required String albumId,
  }) async {
    final user = _requireUser();
    final resolvedSongId = await _resolveSongDocId(
      ownerId: user.uid,
      songId: songId,
    );
    await _linkSongToAlbum(
      ownerId: user.uid,
      albumId: albumId,
      songId: resolvedSongId,
    );
  }

  Future<Song> saveOnlineSongToAlbum({
    required Song song,
    required String albumId,
    String albumTitle = '',
  }) async {
    final user = _requireUser();
    final cleanAlbumId = albumId.trim();
    final sourceId = _youtubeSourceId(song);

    if (cleanAlbumId.isEmpty) {
      throw const LibraryGatewayException('Album is required.');
    }

    final songRef = _songsRef(user.uid).doc(_youtubeDocId(sourceId));
    final existing = await _firebaseRequest(songRef.get(_serverGet));

    if (!existing.exists) {
      await _firebaseRequest(
        songRef.set({
          'ownerId': user.uid,
          'title':
              song.title.trim().isEmpty ? 'Untitled song' : song.title.trim(),
          'artist': song.artist.trim(),
          'album': albumTitle.trim(),
          'durationSeconds': song.duration.inSeconds,
          'streamUrl': '',
          'audioPath': '$_youtubeAudioPrefix$sourceId',
          'coverUrl': song.coverUrl.trim(),
          'coverPath': '',
          'sourceType': _sourceYoutube,
          'sourceId': sourceId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }),
      );
    }

    await _linkSongToAlbum(
      ownerId: user.uid,
      albumId: cleanAlbumId,
      songId: songRef.id,
    );

    final savedDoc = await _firebaseRequest(songRef.get(_serverGet));
    return _songFromDoc(savedDoc);
  }

  User _requireUser() {
    if (!isConfigured) {
      throw const LibraryGatewayException('Firebase is not configured.');
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw const LibraryGatewayException('Login required.');
    }

    return user;
  }

  CollectionReference<Map<String, dynamic>> _albumsRef(String ownerId) {
    return _firestore.collection('users').doc(ownerId).collection('albums');
  }

  CollectionReference<Map<String, dynamic>> _songsRef(String ownerId) {
    return _firestore.collection('users').doc(ownerId).collection('songs');
  }

  CollectionReference<Map<String, dynamic>> _albumItemsRef(
    String ownerId,
    String albumId,
  ) {
    return _albumsRef(ownerId).doc(albumId).collection('items');
  }

  Future<void> _linkSongToAlbum({
    required String ownerId,
    required String albumId,
    required String songId,
  }) async {
    final cleanAlbumId = albumId.trim();
    final cleanSongId = songId.trim();

    if (cleanAlbumId.isEmpty || cleanSongId.isEmpty) {
      return;
    }

    final albumDoc = await _firebaseRequest(
      _albumsRef(ownerId).doc(cleanAlbumId).get(_serverGet),
    );
    if (!albumDoc.exists) {
      throw const LibraryGatewayException('Album not found.');
    }

    final songDoc = await _firebaseRequest(
      _songsRef(ownerId).doc(cleanSongId).get(_serverGet),
    );
    if (!songDoc.exists) {
      throw const LibraryGatewayException('Song not found.');
    }

    final itemRef = _albumItemsRef(ownerId, cleanAlbumId).doc(cleanSongId);
    final existing = await _firebaseRequest(itemRef.get(_serverGet));
    if (existing.exists) {
      return;
    }

    final currentItems = await _firebaseRequest(
      _albumItemsRef(ownerId, cleanAlbumId).get(_serverGet),
    );
    await _firebaseRequest(
      itemRef.set({
        'songId': cleanSongId,
        'position': currentItems.docs.length,
        'createdAt': FieldValue.serverTimestamp(),
      }),
    );
  }

  Future<String> _resolveSongDocId({
    required String ownerId,
    required String songId,
  }) async {
    final cleanSongId = songId.trim();

    if (cleanSongId.isEmpty) {
      throw const LibraryGatewayException('Song id is required.');
    }

    final directDoc = await _firebaseRequest(
      _songsRef(ownerId).doc(cleanSongId).get(_serverGet),
    );
    if (directDoc.exists) {
      return cleanSongId;
    }

    if (_isYoutubeVideoId(cleanSongId)) {
      final youtubeDoc = await _firebaseRequest(
        _songsRef(ownerId).doc(_youtubeDocId(cleanSongId)).get(_serverGet),
      );
      if (youtubeDoc.exists) {
        return youtubeDoc.id;
      }

      final byYoutubeId = await _firebaseRequest(
        _songsRef(ownerId)
            .where('sourceType', isEqualTo: _sourceYoutube)
            .where('sourceId', isEqualTo: cleanSongId)
            .limit(1)
            .get(_serverGet),
      );

      if (byYoutubeId.docs.isNotEmpty) {
        return byYoutubeId.docs.first.id;
      }
    }

    throw const LibraryGatewayException(
      'Song is not saved in your library yet.',
    );
  }

  Future<_UploadedFile> _uploadBinary({
    required String ownerId,
    required String folder,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final objectPath = _storagePath(ownerId, folder, fileName);
    final contentType = lookupMimeType(fileName, headerBytes: bytes) ??
        'application/octet-stream';
    final bucket = folder.startsWith('audio') ? 'songs' : 'covers';

    try {
      final uploaded = await _supabase
          .uploadBinary(
            bucket: bucket,
            objectPath: objectPath,
            bytes: bytes,
            contentType: contentType,
          )
          .timeout(const Duration(seconds: 18));

      return _UploadedFile(
        path: '${uploaded.bucket}/${uploaded.path}',
        url: uploaded.publicUrl,
      );
    } on TimeoutException {
      throw const LibraryGatewayException(
        'Supabase Storage chua phan hoi. Kiem tra bucket songs/covers.',
      );
    } on SupabaseConfigException catch (error) {
      throw LibraryGatewayException('$error');
    } on StorageException catch (error) {
      throw LibraryGatewayException(
        'Supabase Storage loi: ${error.message}',
      );
    }
  }

  Future<T> _firebaseRequest<T>(Future<T> request) async {
    try {
      return await request.timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw const LibraryGatewayException(
        'Firestore chua san sang. Hay bat Firestore Database trong Firebase Console.',
      );
    } on FirebaseException catch (error) {
      final message = error.message ?? '';
      if (error.code == 'permission-denied' ||
          message.contains('firestore.googleapis.com')) {
        throw const LibraryGatewayException(
          'Firestore chua bat hoac rules chua cho phep ghi du lieu.',
        );
      }
      throw LibraryGatewayException(
        message.isEmpty ? 'Firebase error: ${error.code}' : message,
      );
    }
  }

  Playlist _playlistFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    List<Song> songs = const [],
  }) {
    final data = doc.data() ?? const <String, dynamic>{};

    return Playlist(
      id: doc.id,
      title: _string(data['title']),
      subtitle: _string(data['subtitle']),
      coverUrl: _string(data['coverUrl']),
      songs: songs,
    );
  }

  Song _songFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final sourceType = _string(data['sourceType']);
    final sourceId = _string(data['sourceId']);
    final isYoutube = sourceType == _sourceYoutube;

    return Song(
      id: isYoutube ? sourceId : doc.id,
      title: _string(data['title']),
      artist: _string(data['artist']),
      album: _string(data['album']),
      coverUrl: _string(data['coverUrl']),
      duration: Duration(seconds: _int(data['durationSeconds'])),
      streamUrl: isYoutube ? '' : _string(data['streamUrl']),
      databaseId: doc.id,
      sourceType: sourceType,
      sourceId: sourceId,
    );
  }

  String _youtubeSourceId(Song song) {
    final sourceId = song.youtubeVideoId.trim();

    if (!_isYoutubeVideoId(sourceId)) {
      throw LibraryGatewayException('Video YouTube khong hop le: $sourceId');
    }

    return sourceId;
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

  String _string(dynamic value) => value == null ? '' : '$value';

  int _int(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  bool _isYoutubeVideoId(String value) {
    return RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(value.trim());
  }

  String _youtubeDocId(String videoId) => '$_youtubeDocPrefix$videoId';
}

class _UploadedFile {
  final String path;
  final String url;

  const _UploadedFile({
    this.path = '',
    this.url = '',
  });
}

final libraryGateway = LibraryGateway();
