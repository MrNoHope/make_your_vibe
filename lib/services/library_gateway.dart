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
    this.artist = '',
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

  static const _onlineAudioPrefix = 'online:';
  static const _onlineDocPrefix = 'online_';
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

  Future<List<Playlist>> getImportedSharedAlbums() async {
    final user = _requireUser();
    final snapshot = await _firebaseRequest(
      _userSharedAlbumsRef(user.uid)
          .orderBy('addedAt', descending: true)
          .get(_serverGet),
    );

    return snapshot.docs.map(_importedSharedPlaylistFromDoc).toList();
  }

  Future<Playlist> getImportedSharedAlbum(String shareCode) async {
    final user = _requireUser();
    final cleanCode = shareCode.trim();

    if (cleanCode.isEmpty) {
      throw const LibraryGatewayException('Share code is required.');
    }

    final importedDoc = await _firebaseRequest(
      _userSharedAlbumsRef(user.uid).doc(cleanCode).get(_serverGet),
    );
    if (!importedDoc.exists) {
      throw const LibraryGatewayException('Shared album not imported.');
    }

    final album = _importedSharedPlaylistFromDoc(importedDoc);
    final active = await _isSharedAlbumActive(cleanCode);
    if (active) {
      await _incrementSharedAlbumCounter(cleanCode, 'viewCount');
    }
    if (active != album.shareActive) {
      await _firebaseRequest(
        importedDoc.reference.set({
          'shareActive': active,
          'canShare': active,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
      );
    }

    return album.copyWith(
      shareActive: active,
      canShare: active,
    );
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

  Future<String> shareAlbum(String albumId) async {
    final album = await getAlbum(albumId);
    return _sharePlaylist(album);
  }

  Future<String> sharePlaylist(Playlist album) async {
    _requireUser();
    return _sharePlaylist(album);
  }

  Future<String> _sharePlaylist(Playlist album) async {
    final user = _requireUser();
    final cleanAlbumId = album.id.trim();

    if (cleanAlbumId.isEmpty) {
      throw const LibraryGatewayException('Album is required.');
    }
    if (album.songs.isEmpty) {
      throw const LibraryGatewayException('Album needs at least one song.');
    }

    final existing = await _firebaseRequest(
      _sharedAlbumsRef()
          .where('ownerId', isEqualTo: user.uid)
          .where('albumId', isEqualTo: cleanAlbumId)
          .limit(1)
          .get(_serverGet),
    );
    final shareRef = existing.docs.isEmpty
        ? _sharedAlbumsRef().doc()
        : existing.docs.first.reference;

    await _firebaseRequest(
      shareRef.set({
        'ownerId': user.uid,
        'ownerName': user.displayName ?? user.email ?? 'Make Your Vibe',
        'albumId': cleanAlbumId,
        'title': album.title,
        'subtitle': album.subtitle,
        'coverUrl': album.coverUrl,
        'songs': album.songs.map(_songShareData).toList(growable: false),
        'active': true,
        'viewCount': existing.docs.isEmpty
            ? 0
            : _int(existing.docs.first.data()['viewCount']),
        'importCount': existing.docs.isEmpty
            ? 0
            : _int(existing.docs.first.data()['importCount']),
        'favoriteCount': existing.docs.isEmpty
            ? 0
            : _int(existing.docs.first.data()['favoriteCount']),
        'inviteCount': existing.docs.isEmpty
            ? 0
            : _int(existing.docs.first.data()['inviteCount']),
        'stoppedAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (existing.docs.isEmpty) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );

    return shareRef.id;
  }

  Future<Playlist> importSharedAlbum(String shareCode) async {
    final user = _requireUser();
    final resolved = await _resolveSharedAlbumCode(shareCode);
    final sharedAlbum = _sharedPlaylistFromDoc(resolved.doc);
    final docRef = _userSharedAlbumsRef(user.uid).doc(sharedAlbum.id);
    final existingImport = await _firebaseRequest(docRef.get(_serverGet));

    await _firebaseRequest(
      docRef.set({
        'title': sharedAlbum.title,
        'subtitle': sharedAlbum.subtitle,
        'coverUrl': sharedAlbum.coverUrl,
        'shareId': sharedAlbum.id,
        'ownerId': _string(resolved.doc.data()?['ownerId']),
        'ownerName': _string(resolved.doc.data()?['ownerName']),
        'songs': sharedAlbum.songs.map(_songShareData).toList(growable: false),
        'shareActive': true,
        'canShare': true,
        if (resolved.inviteId.isNotEmpty) 'sourceInviteId': resolved.inviteId,
        if (!existingImport.exists) 'addedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );

    await _incrementSharedAlbumCounter(sharedAlbum.id, 'viewCount');
    if (!existingImport.exists) {
      await _incrementSharedAlbumCounter(sharedAlbum.id, 'importCount');
      await _incrementSharedAlbumCounter(sharedAlbum.id, 'favoriteCount');
    }
    if (resolved.inviteId.isNotEmpty) {
      await _incrementInviteCounter(resolved.inviteId, 'openCount');
    }

    return sharedAlbum;
  }

  Future<Playlist> getSharedAlbum(String shareCode) async {
    final resolved = await _resolveSharedAlbumCode(shareCode);
    await _incrementSharedAlbumCounter(resolved.doc.id, 'viewCount');
    if (resolved.inviteId.isNotEmpty) {
      await _incrementInviteCounter(resolved.inviteId, 'openCount');
    }

    return _sharedPlaylistFromDoc(resolved.doc);
  }

  Future<String> createSharedAlbumInvite(String shareCode) async {
    final user = _requireUser();
    final cleanCode = shareCode.trim();

    if (cleanCode.isEmpty) {
      throw const LibraryGatewayException('Share code is required.');
    }

    final importedDoc = await _firebaseRequest(
      _userSharedAlbumsRef(user.uid).doc(cleanCode).get(_serverGet),
    );
    if (!importedDoc.exists) {
      throw const LibraryGatewayException('Shared album not imported.');
    }

    final sharedDoc = await _firebaseRequest(
      _sharedAlbumsRef().doc(cleanCode).get(_serverGet),
    );
    if (!sharedDoc.exists || sharedDoc.data()?['active'] == false) {
      await _firebaseRequest(
        importedDoc.reference.set({
          'shareActive': false,
          'canShare': false,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
      );
      throw const LibraryGatewayException(
        'Album này đã ngừng chia sẻ. Bạn vẫn nghe được nhưng không thể gửi mã mới.',
      );
    }

    final inviteRef = _sharedAlbumInvitesRef().doc();
    await _firebaseRequest(
      inviteRef.set({
        'shareId': cleanCode,
        'createdBy': user.uid,
        'createdByName': user.displayName ?? user.email ?? 'Make Your Vibe',
        'active': true,
        'openCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }),
    );
    await _incrementSharedAlbumCounter(cleanCode, 'inviteCount');

    return inviteRef.id;
  }

  Future<void> stopSharingAlbum(String shareCode) async {
    final user = _requireUser();
    final cleanCode = shareCode.trim();

    if (cleanCode.isEmpty) {
      throw const LibraryGatewayException('Share code is required.');
    }

    final doc = await _firebaseRequest(
      _sharedAlbumsRef().doc(cleanCode).get(_serverGet),
    );
    if (!doc.exists) {
      throw const LibraryGatewayException('Shared album not found.');
    }
    if (_string(doc.data()?['ownerId']) != user.uid) {
      throw const LibraryGatewayException('Only owner can stop sharing.');
    }

    await _firebaseRequest(
      doc.reference.set({
        'active': false,
        'stoppedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
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

  Future<void> removeSongFromAlbum({
    required Song song,
    required String albumId,
  }) async {
    final user = _requireUser();
    final cleanAlbumId = albumId.trim();
    if (cleanAlbumId.isEmpty) {
      throw const LibraryGatewayException('Album is required.');
    }

    final songId = await _resolveSongDocId(
      ownerId: user.uid,
      songId: song.storedId,
    );
    await _firebaseRequest(
      _albumItemsRef(user.uid, cleanAlbumId).doc(songId).delete(),
    );
  }

  Future<void> deleteUploadedSong(Song song) async {
    final user = _requireUser();
    final songId = await _resolveSongDocId(
      ownerId: user.uid,
      songId: song.storedId,
    );
    final songRef = _songsRef(user.uid).doc(songId);
    final songDoc = await _firebaseRequest(songRef.get(_serverGet));
    if (!songDoc.exists) {
      throw const LibraryGatewayException('Song not found.');
    }

    final data = songDoc.data() ?? const <String, dynamic>{};
    if (_string(data['sourceType']) != _sourceUpload) {
      throw const LibraryGatewayException(
        'Only uploaded songs can be deleted.',
      );
    }

    final albumSnapshot = await _firebaseRequest(
      _albumsRef(user.uid).get(_serverGet),
    );
    final batch = _firestore.batch();
    for (final albumDoc in albumSnapshot.docs) {
      batch.delete(_albumItemsRef(user.uid, albumDoc.id).doc(songId));
    }
    batch.delete(songRef);
    await _firebaseRequest(batch.commit());

    await _deleteStoredFile(_string(data['audioPath']));
    await _deleteStoredFile(_string(data['coverPath']));
  }

  Future<Song> saveSongToAlbum({
    required Song song,
    required String albumId,
    String albumTitle = '',
  }) async {
    if (song.isOnline) {
      return saveOnlineSongToAlbum(
        song: song,
        albumId: albumId,
        albumTitle: albumTitle,
      );
    }

    final user = _requireUser();
    final cleanAlbumId = albumId.trim();
    if (cleanAlbumId.isEmpty) {
      throw const LibraryGatewayException('Album is required.');
    }

    final localId = song.databaseId.trim();
    if (localId.isNotEmpty) {
      final localDoc = await _firebaseRequest(
        _songsRef(user.uid).doc(localId).get(_serverGet),
      );
      if (localDoc.exists) {
        await _linkSongToAlbum(
          ownerId: user.uid,
          albumId: cleanAlbumId,
          songId: localId,
        );
        return _songFromDoc(localDoc);
      }
    }

    if (song.sourceType == _sourceUpload && song.streamUrl.trim().isNotEmpty) {
      final sourceKey = song.sourceId.trim().isNotEmpty
          ? song.sourceId.trim()
          : song.id.trim();
      final songRef = _songsRef(user.uid).doc(
        _onlineDocId('shared_upload', sourceKey),
      );
      final existing = await _firebaseRequest(songRef.get(_serverGet));

      if (!existing.exists) {
        await _firebaseRequest(
          songRef.set({
            'ownerId': user.uid,
            'title': song.title.trim().isEmpty ? 'Untitled song' : song.title,
            'artist': song.artist.trim(),
            'album': albumTitle.trim(),
            'durationSeconds': song.duration.inSeconds,
            'streamUrl': song.streamUrl.trim(),
            'audioPath': 'shared:$sourceKey',
            'coverUrl': song.coverUrl.trim(),
            'coverPath': '',
            'sourceType': _sourceUpload,
            'sourceId': sourceKey,
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

    final resolvedSongId = await _resolveSongDocId(
      ownerId: user.uid,
      songId: song.storedId,
    );
    await _linkSongToAlbum(
      ownerId: user.uid,
      albumId: cleanAlbumId,
      songId: resolvedSongId,
    );
    final savedDoc = await _firebaseRequest(
      _songsRef(user.uid).doc(resolvedSongId).get(_serverGet),
    );
    return _songFromDoc(savedDoc);
  }

  Future<Song> saveOnlineSongToAlbum({
    required Song song,
    required String albumId,
    String albumTitle = '',
  }) async {
    final user = _requireUser();
    final cleanAlbumId = albumId.trim();
    final sourceType = _onlineSourceType(song);
    final sourceId = _onlineSourceId(song);

    if (cleanAlbumId.isEmpty) {
      throw const LibraryGatewayException('Album is required.');
    }

    final songRef = _songsRef(user.uid).doc(_onlineDocId(sourceType, sourceId));
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
          'audioPath': '$_onlineAudioPrefix$sourceType:$sourceId',
          'coverUrl': song.coverUrl.trim(),
          'coverPath': '',
          'sourceType': sourceType,
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

  CollectionReference<Map<String, dynamic>> _userSharedAlbumsRef(
    String ownerId,
  ) {
    return _firestore
        .collection('users')
        .doc(ownerId)
        .collection('sharedAlbums');
  }

  CollectionReference<Map<String, dynamic>> _sharedAlbumsRef() {
    return _firestore.collection('sharedAlbums');
  }

  CollectionReference<Map<String, dynamic>> _sharedAlbumInvitesRef() {
    return _firestore.collection('sharedAlbumInvites');
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

    final youtubeDoc = await _firebaseRequest(
      _songsRef(ownerId).doc(_onlineDocId(_sourceYoutube, cleanSongId)).get(
            _serverGet,
          ),
    );
    if (youtubeDoc.exists) {
      return youtubeDoc.id;
    }

    final bySourceId = await _firebaseRequest(
      _songsRef(ownerId)
          .where('sourceId', isEqualTo: cleanSongId)
          .limit(1)
          .get(_serverGet),
    );

    if (bySourceId.docs.isNotEmpty) {
      return bySourceId.docs.first.id;
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

  Future<void> _deleteStoredFile(String storedPath) async {
    final cleanPath = storedPath.trim();
    final separator = cleanPath.indexOf('/');
    if (separator <= 0 || cleanPath.startsWith('shared:')) {
      return;
    }

    final bucket = cleanPath.substring(0, separator);
    final objectPath = cleanPath.substring(separator + 1);
    if (objectPath.isEmpty) {
      return;
    }

    try {
      await _supabase
          .deleteObject(bucket: bucket, objectPath: objectPath)
          .timeout(const Duration(seconds: 12));
    } catch (_) {
      // Firestore is already cleaned up; an orphaned storage file is harmless.
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

  Future<_ResolvedSharedAlbum> _resolveSharedAlbumCode(String shareCode) async {
    final cleanCode = shareCode.trim();

    if (cleanCode.isEmpty) {
      throw const LibraryGatewayException('Share code is required.');
    }

    _requireUser();
    var doc = await _firebaseRequest(
      _sharedAlbumsRef().doc(cleanCode).get(_serverGet),
    );
    var inviteId = '';

    if (!doc.exists) {
      final inviteDoc = await _firebaseRequest(
        _sharedAlbumInvitesRef().doc(cleanCode).get(_serverGet),
      );
      if (!inviteDoc.exists || inviteDoc.data()?['active'] == false) {
        throw const LibraryGatewayException('Shared album not found.');
      }

      final shareId = _string(inviteDoc.data()?['shareId']).trim();
      if (shareId.isEmpty) {
        throw const LibraryGatewayException('Shared album not found.');
      }

      doc = await _firebaseRequest(
        _sharedAlbumsRef().doc(shareId).get(_serverGet),
      );
      inviteId = cleanCode;
    }

    if (!doc.exists) {
      throw const LibraryGatewayException('Shared album not found.');
    }
    if (doc.data()?['active'] == false) {
      throw const LibraryGatewayException('Album này đã ngừng chia sẻ.');
    }

    return _ResolvedSharedAlbum(doc: doc, inviteId: inviteId);
  }

  Future<bool> _isSharedAlbumActive(String shareCode) async {
    final cleanCode = shareCode.trim();
    if (cleanCode.isEmpty) {
      return false;
    }

    final doc = await _firebaseRequest(
      _sharedAlbumsRef().doc(cleanCode).get(_serverGet),
    );
    return doc.exists && doc.data()?['active'] != false;
  }

  Future<void> _incrementSharedAlbumCounter(
    String shareCode,
    String field,
  ) async {
    final cleanCode = shareCode.trim();
    if (cleanCode.isEmpty) {
      return;
    }

    await _firebaseRequest(
      _sharedAlbumsRef().doc(cleanCode).set({
        field: FieldValue.increment(1),
        'lastAccessedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
  }

  Future<void> _incrementInviteCounter(String inviteId, String field) async {
    final cleanInviteId = inviteId.trim();
    if (cleanInviteId.isEmpty) {
      return;
    }

    await _firebaseRequest(
      _sharedAlbumInvitesRef().doc(cleanInviteId).set({
        field: FieldValue.increment(1),
        'lastOpenedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
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

  Playlist _importedSharedPlaylistFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final rawSongs = data['songs'];
    final shareActive = data['shareActive'] != false;
    final songs = rawSongs is List
        ? rawSongs
            .whereType<Map>()
            .map((raw) => Song.fromJson(raw.cast<String, dynamic>()))
            .toList(growable: false)
        : const <Song>[];

    return Playlist(
      id: doc.id,
      title: _string(data['title']),
      subtitle: _string(data['subtitle']),
      coverUrl: _string(data['coverUrl']),
      songs: songs,
      shareId: _string(data['shareId']).trim().isEmpty
          ? doc.id
          : _string(data['shareId']),
      isShared: true,
      shareActive: shareActive,
      canShare: shareActive && data['canShare'] != false,
    );
  }

  Playlist _sharedPlaylistFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final rawSongs = data['songs'];
    final ownerName = _string(data['ownerName']).trim();
    final subtitle = _string(data['subtitle']).trim();
    final songs = rawSongs is List
        ? rawSongs
            .whereType<Map>()
            .map((raw) => Song.fromJson(raw.cast<String, dynamic>()))
            .toList(growable: false)
        : const <Song>[];

    return Playlist(
      id: doc.id,
      title: _string(data['title']),
      subtitle: ownerName.isEmpty
          ? subtitle
          : subtitle.isEmpty
              ? 'Chia sẻ bởi $ownerName'
              : '$subtitle • $ownerName',
      coverUrl: _string(data['coverUrl']),
      songs: songs,
      shareId: doc.id,
      isShared: true,
      shareActive: data['active'] != false,
      canShare: data['active'] != false,
      viewCount: _int(data['viewCount']),
      importCount: _int(data['importCount']),
      favoriteCount: _int(data['favoriteCount']),
      inviteCount: _int(data['inviteCount']),
    );
  }

  Song _songFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final sourceType = _string(data['sourceType']);
    final sourceId = _string(data['sourceId']);
    final isOnline = sourceType.isNotEmpty && sourceType != _sourceUpload;

    return Song(
      id: isOnline && sourceId.isNotEmpty ? sourceId : doc.id,
      title: _string(data['title']),
      artist: _string(data['artist']),
      album: _string(data['album']),
      coverUrl: _string(data['coverUrl']),
      duration: Duration(seconds: _int(data['durationSeconds'])),
      streamUrl: isOnline ? '' : _string(data['streamUrl']),
      databaseId: doc.id,
      sourceType: sourceType,
      sourceId: sourceId,
    );
  }

  Map<String, dynamic> _songShareData(Song song) {
    return {
      'id': song.id,
      'title': song.title,
      'artist': song.artist,
      'album': song.album,
      'coverUrl': song.coverUrl,
      'durationSeconds': song.duration.inSeconds,
      'streamUrl': song.sourceType == _sourceUpload ? song.streamUrl : '',
      'sourceType': song.sourceType,
      'sourceId': song.sourceId,
    };
  }

  String _onlineSourceType(Song song) {
    final sourceType = song.sourceType.trim();
    return sourceType.isEmpty || sourceType == _sourceUpload
        ? _sourceYoutube
        : sourceType;
  }

  String _onlineSourceId(Song song) {
    final sourceId = song.onlineSourceId.trim();

    if (sourceId.isEmpty) {
      throw const LibraryGatewayException('Online song id is required.');
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

  String _safeDocSegment(String value) {
    final safe = value.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    return safe.isEmpty ? 'song' : safe;
  }

  String _onlineDocId(String sourceType, String sourceId) {
    return '$_onlineDocPrefix${_safeDocSegment(sourceType)}_${_safeDocSegment(sourceId)}';
  }
}

class _UploadedFile {
  final String path;
  final String url;

  const _UploadedFile({
    this.path = '',
    this.url = '',
  });
}

class _ResolvedSharedAlbum {
  final DocumentSnapshot<Map<String, dynamic>> doc;
  final String inviteId;

  const _ResolvedSharedAlbum({
    required this.doc,
    this.inviteId = '',
  });
}

final libraryGateway = LibraryGateway();
