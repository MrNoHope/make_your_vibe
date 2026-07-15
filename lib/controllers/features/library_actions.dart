part of app_controller;

extension AppLibraryActions on AppController {
  Future<void> toggleLike(Song song) async {
    if (liked.contains(song.id)) {
      liked.remove(song.id);
    } else {
      liked.add(song.id);
      await _rememberSong(song);
    }
    await store.setMaps(
      _key('liked_songs'),
      liked.map((id) => {'id': id}),
    );
    notifyListeners();
  }

  Future<void> createPlaylist(String name) async {
    if (name.trim().isEmpty) return;
    playlists.add(
      PlaylistModel(
        id: 'pl_${DateTime.now().microsecondsSinceEpoch}',
        name: name.trim(),
      ),
    );
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> addToPlaylist(String playlistId, Song song) async {
    final index = playlists.indexWhere((item) => item.id == playlistId);
    if (index < 0) return;
    final ids = [...playlists[index].songIds];
    if (!ids.contains(song.id)) ids.add(song.id);
    playlists[index] = playlists[index].copyWith(songIds: ids);
    await _rememberSong(song);
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> removeFromPlaylist(String playlistId, String songId) async {
    final index = playlists.indexWhere((item) => item.id == playlistId);
    if (index < 0) return;
    playlists[index] = playlists[index].copyWith(
      songIds: playlists[index]
          .songIds
          .where((id) => id != songId)
          .toList(),
    );
    await _savePlaylists();
    notifyListeners();
  }

  Future<void> deletePlaylist(String playlistId) async {
    playlists.removeWhere((item) => item.id == playlistId);
    await _savePlaylists();
    notifyListeners();
  }

  List<Song> songsFor(PlaylistModel playlist) => playlist.songIds
      .map(
        (id) => allSongs.where((song) => song.id == id).firstOrNull,
      )
      .whereType<Song>()
      .toList();

  Future<String> pickUploadCover() => media.pickAndCopy(
        type: FileType.image,
        folder: '${user!.id}/covers',
      );

  Future<String> pickVibeCover() => media.pickAndCopy(
        type: FileType.image,
        folder: '${user!.id}/vibe_covers',
      );

  Future<void> uploadSong({
    required String title,
    required String artist,
    required bool isPublic,
    String artworkPath = '',
  }) async {
    final path = await media.pickAndCopy(
      type: FileType.audio,
      folder: '${user!.id}/uploads',
    );
    if (path.isEmpty) {
      await media.delete(artworkPath);
      return;
    }
    final song = Song(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      title: title.trim().isEmpty ? 'My song' : title.trim(),
      artist: artist.trim().isEmpty
          ? (user?.displayName ?? 'Local artist')
          : artist.trim(),
      artworkUrl: artworkPath,
      source: SongSource.local,
      localPath: path,
      isPublic: isPublic,
    );
    uploads.insert(0, song);
    await _saveUploads();
    notifyListeners();
  }

  Future<void> updateUpload(
    Song song, {
    required String title,
    required String artist,
    required bool isPublic,
    String artworkPath = '',
  }) async {
    final index = uploads.indexWhere((item) => item.id == song.id);
    if (index < 0) return;
    final nextArtwork = artworkPath.isEmpty ? song.artworkUrl : artworkPath;
    final updated = song.copyWith(
      title: title.trim().isEmpty ? song.title : title.trim(),
      artist: artist.trim().isEmpty ? song.artist : artist.trim(),
      artworkUrl: nextArtwork,
      isPublic: isPublic,
    );
    uploads[index] = updated;
    if (artworkPath.isNotEmpty && artworkPath != song.artworkUrl) {
      await media.delete(song.artworkUrl);
    }
    if (currentSong?.id == song.id) currentSong = updated;
    await _saveUploads();
    notifyListeners();
  }

  Future<void> deleteUpload(Song song) async {
    if (currentSong?.id == song.id) {
      _request++;
      await audio.reset();
      currentSong = null;
      position = Duration.zero;
      duration = Duration.zero;
      playing = false;
      preparing = false;
      loadingSongId = '';
    }
    uploads.removeWhere((item) => item.id == song.id);
    recent.removeWhere((item) => item.id == song.id);
    queue.removeWhere((item) => item.id == song.id);
    queueIndex = currentSong == null
        ? -1
        : queue.indexWhere((item) => item.id == currentSong!.id);
    liked.remove(song.id);
    for (var index = 0; index < playlists.length; index++) {
      playlists[index] = playlists[index].copyWith(
        songIds: playlists[index]
            .songIds
            .where((id) => id != song.id)
            .toList(),
      );
    }
    await media.delete(song.localPath);
    await media.delete(song.artworkUrl);
    await _saveUploads();
    await _savePlaylists();
    await store.setMaps(
      _key('recent'),
      recent.map((item) => item.toMap()),
    );
    await store.setMaps(
      _key('liked_songs'),
      liked.map((id) => {'id': id}),
    );
    notifyListeners();
  }

}
