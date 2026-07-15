import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/playlist.dart';
import '../models/song.dart';
import '../services/audio_gateway.dart';
import '../services/music_gateway.dart';

enum VibeRepeatMode {
  off,
  song,
  songOnce,
}

enum PlayOriginType {
  none,
  search,
  album,
  playlist,
  library,
}

class PlayContextInfo {
  final PlayOriginType type;
  final String title;

  const PlayContextInfo({
    this.type = PlayOriginType.none,
    this.title = '',
  });

  bool get hasTitle => title.trim().isNotEmpty;
}

class VibeController extends ChangeNotifier {
  final MusicGateway music = musicGateway;
  final AudioGateway audio = audioGateway;

  static const _lastSongKey = 'make_your_vibe.last_song';
  static const _listeningHistoryKey = 'make_your_vibe.listening_history';
  static const _searchHistoryKey = 'make_your_vibe.search_history';
  static const _favoriteSongsKey = 'make_your_vibe.favorite_songs';
  static const _favoriteAlbumsKey = 'make_your_vibe.favorite_albums';
  static const _maxListeningHistory = 24;
  static const _maxSearchHistory = 16;

  Song? currentSong;
  List<Song> homeSongs = [];
  List<Song> searchResults = [];
  List<Song> activeQueue = [];
  List<Song> listeningHistory = [];
  List<Song> favoriteSongs = [];
  List<Playlist> favoriteAlbums = [];
  List<String> searchHistory = [];

  Duration position = Duration.zero;
  Duration? duration;
  bool isPlaying = false;
  bool loadingHome = false;
  bool searching = false;
  bool resolving = false;
  bool _handlingCompletion = false;
  bool _playRequested = false;
  bool _repeatOnceUsed = false;
  bool _seeking = false;
  bool shuffleEnabled = false;
  int currentIndex = 0;
  String errorMessage = '';
  PlayContextInfo playContext = const PlayContextInfo();
  VibeRepeatMode repeatMode = VibeRepeatMode.off;
  final Random _random = Random();
  final List<int> _shuffleRemaining = [];
  String _activeQueueSignature = '';

  StreamSubscription<ja.PlayerState>? _audioStateSub;
  StreamSubscription<Duration>? _audioPositionSub;
  StreamSubscription<Duration?>? _audioDurationSub;
  StreamSubscription<Object>? _audioErrorSub;
  StreamSubscription<AudioGatewayCommand>? _audioCommandSub;

  VibeController() {
    _audioStateSub = audio.playerStateStream.listen((state) {
      isPlaying = state.playing ||
          (_playRequested &&
              state.processingState == ja.ProcessingState.buffering);
      resolving = false;
      if (state.processingState == ja.ProcessingState.completed &&
          !_handlingCompletion &&
          !_seeking) {
        unawaited(_handleSongCompleted());
      }
      notifyListeners();
    });
    _audioPositionSub = audio.positionStream.listen((value) {
      position = value;
      notifyListeners();
    });
    _audioDurationSub = audio.durationStream.listen((value) {
      duration = value;
      notifyListeners();
    });
    _audioErrorSub = audio.playbackErrorStream.listen((error) {
      resolving = false;
      isPlaying = false;
      errorMessage = 'Khong phat duoc bai nay: $error';
      notifyListeners();
    });
    _audioCommandSub = audio.commandStream.listen((command) {
      switch (command) {
        case AudioGatewayCommand.previous:
          unawaited(previousSong());
        case AudioGatewayCommand.next:
          unawaited(nextSong());
      }
    });
    unawaited(_restoreLastSong());
    unawaited(_restoreHistories());
  }

  Future<void> loadHomeSongs() async {
    if (loadingHome || homeSongs.isNotEmpty) {
      return;
    }

    loadingHome = true;
    errorMessage = '';
    notifyListeners();

    try {
      homeSongs = await music.getHomeTracks();
      _setActiveQueue(homeSongs);
      currentIndex = 0;
    } catch (error) {
      errorMessage = 'Khong tai duoc nhac: $error';
    }

    loadingHome = false;
    notifyListeners();
  }

  Future<void> searchSongs(String keyword) async {
    final query = keyword.trim();

    if (query.isEmpty) {
      searchResults = [];
      notifyListeners();
      return;
    }

    searching = true;
    errorMessage = '';
    notifyListeners();

    try {
      searchResults = await music.searchTracks(query);
      _setActiveQueue(searchResults);
      currentIndex = 0;
      unawaited(_addSearchHistory(query));
    } catch (error) {
      errorMessage = 'Search loi: $error';
    }

    searching = false;
    notifyListeners();
  }

  void cycleRepeatMode() {
    repeatMode = switch (repeatMode) {
      VibeRepeatMode.off => VibeRepeatMode.song,
      VibeRepeatMode.song => VibeRepeatMode.songOnce,
      VibeRepeatMode.songOnce => VibeRepeatMode.off,
    };
    _repeatOnceUsed = false;
    notifyListeners();
  }

  void toggleShuffle() {
    shuffleEnabled = !shuffleEnabled;
    _resetShuffleCycle();
    notifyListeners();
  }

  Future<void> _handleSongCompleted() async {
    _handlingCompletion = true;

    try {
      switch (repeatMode) {
        case VibeRepeatMode.off:
          await nextSong();
        case VibeRepeatMode.song:
          await _replayCurrentSong();
        case VibeRepeatMode.songOnce:
          if (_repeatOnceUsed) {
            repeatMode = VibeRepeatMode.off;
            _repeatOnceUsed = false;
            notifyListeners();
            await nextSong();
          } else {
            _repeatOnceUsed = true;
            await _replayCurrentSong();
          }
      }
    } finally {
      _handlingCompletion = false;
    }
  }

  Future<void> _replayCurrentSong() async {
    final song = activeQueue.isNotEmpty && currentIndex < activeQueue.length
        ? activeQueue[currentIndex]
        : currentSong;

    if (song == null) {
      return;
    }

    await playSong(
      song,
      queue: activeQueue.isEmpty ? [song] : activeQueue,
      resetRepeatOnceProgress: false,
    );
  }

  Future<void> playSong(
    Song song, {
    List<Song>? queue,
    PlayContextInfo? context,
    bool resetRepeatOnceProgress = true,
  }) async {
    final chosenQueue = queue ?? activeQueue;

    if (chosenQueue.isNotEmpty) {
      _setActiveQueue(chosenQueue);
      final foundIndex = chosenQueue.indexWhere((item) => item.id == song.id);
      currentIndex = foundIndex < 0 ? 0 : foundIndex;
    }

    resolving = true;
    errorMessage = '';
    if (context != null) {
      playContext = context;
    }
    currentSong = song;
    position = Duration.zero;
    duration = song.duration == Duration.zero ? null : song.duration;
    if (resetRepeatOnceProgress) {
      _repeatOnceUsed = false;
    }
    notifyListeners();

    try {
      await audio.stop();
      final playableSong = await music.resolveStream(song);
      currentSong = playableSong;
      duration =
          playableSong.duration == Duration.zero ? null : playableSong.duration;
      await audio.play(playableSong);
      _playRequested = true;
      isPlaying = true;
      unawaited(_saveLastSong(playableSong));
      unawaited(_addListeningHistory(playableSong));
    } catch (error) {
      errorMessage = 'Khong phat duoc bai nay: $error';
      _playRequested = false;
      isPlaying = false;
    }

    resolving = false;
    notifyListeners();
  }

  Future<void> togglePlay() async {
    final song = currentSong;

    if (song == null) {
      if (activeQueue.isNotEmpty) {
        await playSong(activeQueue.first, queue: activeQueue);
      }
      return;
    }

    if (audio.isPlaying || isPlaying) {
      _playRequested = false;
      await audio.pause();
      isPlaying = false;
    } else if (!song.hasStream) {
      await playSong(song, queue: activeQueue.isEmpty ? [song] : activeQueue);
    } else {
      try {
        _playRequested = true;
        await audio.resume();
        isPlaying = true;
      } catch (_) {
        await playSong(song, queue: activeQueue.isEmpty ? [song] : activeQueue);
      }
    }

    notifyListeners();
  }

  Future<void> nextSong() async {
    if (activeQueue.isEmpty) {
      return;
    }

    final nextIndex = _nextQueueIndex();
    currentIndex = nextIndex;
    await playSong(activeQueue[nextIndex], queue: activeQueue);
  }

  int _nextQueueIndex() {
    if (!shuffleEnabled || activeQueue.length <= 1) {
      return currentIndex + 1 >= activeQueue.length ? 0 : currentIndex + 1;
    }

    _shuffleRemaining.remove(currentIndex);

    if (_shuffleRemaining.isEmpty) {
      _shuffleRemaining
        ..clear()
        ..addAll(
          List<int>.generate(activeQueue.length, (index) => index).where(
            (index) => index != currentIndex,
          ),
        )
        ..shuffle(_random);
    }

    return _shuffleRemaining.removeAt(0);
  }

  Future<void> previousSong() async {
    if (activeQueue.isEmpty) {
      return;
    }

    if (position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    final previousIndex =
        currentIndex - 1 < 0 ? activeQueue.length - 1 : currentIndex - 1;
    currentIndex = previousIndex;
    _shuffleRemaining.remove(previousIndex);
    await playSong(activeQueue[previousIndex], queue: activeQueue);
  }

  void _setActiveQueue(List<Song> queue) {
    final signature = queue.map((song) => song.id).join('|');

    if (signature != _activeQueueSignature) {
      _activeQueueSignature = signature;
      _resetShuffleCycle();
    }

    activeQueue = queue;
  }

  void _resetShuffleCycle() {
    _shuffleRemaining.clear();
  }

  Future<void> rewindTenSeconds() async {
    final nextPosition = position - const Duration(seconds: 10);
    await seek(nextPosition.isNegative ? Duration.zero : nextPosition);
  }

  Future<void> seek(Duration nextPosition) async {
    final targetPosition = _safeSeekPosition(nextPosition);
    final song = currentSong;
    final shouldResume = _playRequested || audio.isPlaying || isPlaying;

    _seeking = true;
    errorMessage = '';

    try {
      await audio.seek(targetPosition);
    } catch (error) {
      errorMessage = 'Khong tua duoc bai nay: $error';
      _playRequested = false;
      isPlaying = false;
    } finally {
      _seeking = false;
      resolving = false;
    }
    position = targetPosition;

    if (shouldResume && song != null && errorMessage.isEmpty) {
      _playRequested = true;
      await audio.resume();
      isPlaying = true;
      unawaited(_resumeAfterSeekIfNeeded());
    }

    notifyListeners();
  }

  Future<void> _resumeAfterSeekIfNeeded() async {
    for (final delay in const [
      Duration(milliseconds: 350),
      Duration(milliseconds: 1200),
    ]) {
      await Future<void>.delayed(delay);

      if (!_playRequested || currentSong == null) {
        return;
      }

      if (!audio.isPlaying) {
        await audio.resume();
        isPlaying = true;
        notifyListeners();
      }
    }
  }

  Duration _safeSeekPosition(Duration nextPosition) {
    if (nextPosition.isNegative) {
      return Duration.zero;
    }

    final knownDuration = duration ?? currentSong?.duration ?? Duration.zero;

    if (knownDuration <= Duration.zero) {
      return nextPosition;
    }

    final endGuard = knownDuration - const Duration(milliseconds: 500);

    if (endGuard > Duration.zero && nextPosition > endGuard) {
      return endGuard;
    }

    return nextPosition;
  }

  Future<void> reset() async {
    await audio.stop();
    currentSong = null;
    isPlaying = false;
    _playRequested = false;
    resolving = false;
    position = Duration.zero;
    duration = null;
    currentIndex = 0;
    unawaited(_clearLastSong());
    notifyListeners();
  }

  Future<void> _restoreLastSong() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_lastSongKey);

      if (raw == null || raw.trim().isEmpty) {
        return;
      }

      final restored = Song.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (!_isSupportedSongSource(restored)) {
        unawaited(_clearLastSong());
        return;
      }

      currentSong = restored;
      duration =
          currentSong?.duration == Duration.zero ? null : currentSong?.duration;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveLastSong(Song song) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = _cacheableSong(song);
      await prefs.setString(_lastSongKey, jsonEncode(cached.toJson()));
    } catch (_) {}
  }

  Future<void> _clearLastSong() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastSongKey);
    } catch (_) {}
  }

  Future<void> clearListeningHistory() async {
    listeningHistory = [];
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_listeningHistoryKey);
    } catch (_) {}
  }

  bool isFavoriteSong(Song song) {
    final cleanId = _historySongKey(song);
    return favoriteSongs.any((item) => _historySongKey(item) == cleanId);
  }

  Future<void> toggleFavoriteSong(Song song) async {
    if (isFavoriteSong(song)) {
      await removeFavoriteSong(song);
      return;
    }

    await addFavoriteSong(song);
  }

  Future<void> addFavoriteSong(Song song) async {
    final cached = _cacheableSong(song);
    final cleanId = _historySongKey(cached);

    favoriteSongs = [
      cached,
      ...favoriteSongs.where((item) => _historySongKey(item) != cleanId),
    ];
    notifyListeners();
    await _saveFavoriteSongs();
  }

  Future<void> removeFavoriteSong(Song song) async {
    final cleanId = _historySongKey(song);

    favoriteSongs = favoriteSongs
        .where((item) => _historySongKey(item) != cleanId)
        .toList(growable: false);
    notifyListeners();
    await _saveFavoriteSongs();
  }

  Future<void> clearFavoriteSongs() async {
    favoriteSongs = [];
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_favoriteSongsKey);
    } catch (_) {}
  }

  bool isFavoriteAlbum(Playlist album) {
    final cleanId = _favoriteAlbumKey(album);
    return favoriteAlbums.any((item) => _favoriteAlbumKey(item) == cleanId);
  }

  Future<void> toggleFavoriteAlbum(Playlist album) async {
    if (isFavoriteAlbum(album)) {
      await removeFavoriteAlbum(album);
      return;
    }

    await addFavoriteAlbum(album);
  }

  Future<void> addFavoriteAlbum(Playlist album) async {
    final cached = album.copyWith(
      songs: album.songs.map(_cacheableSong).toList(growable: false),
    );
    final cleanId = _favoriteAlbumKey(cached);

    favoriteAlbums = [
      cached,
      ...favoriteAlbums.where((item) => _favoriteAlbumKey(item) != cleanId),
    ];
    notifyListeners();
    await _saveFavoriteAlbums();
  }

  Future<void> removeFavoriteAlbum(Playlist album) async {
    final cleanId = _favoriteAlbumKey(album);
    favoriteAlbums = favoriteAlbums
        .where((item) => _favoriteAlbumKey(item) != cleanId)
        .toList(growable: false);
    notifyListeners();
    await _saveFavoriteAlbums();
  }

  Future<void> clearSearchHistory() async {
    searchHistory = [];
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_searchHistoryKey);
    } catch (_) {}
  }

  Future<void> removeSearchHistory(String value) async {
    final cleanValue = value.trim().toLowerCase();
    searchHistory = searchHistory
        .where((item) => item.trim().toLowerCase() != cleanValue)
        .toList();
    notifyListeners();
    await _saveSearchHistory();
  }

  Future<void> _restoreHistories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawSongs = prefs.getStringList(_listeningHistoryKey) ?? const [];
      final rawSearches = prefs.getStringList(_searchHistoryKey) ?? const [];
      final rawFavorites = prefs.getStringList(_favoriteSongsKey) ?? const [];
      final rawFavoriteAlbums =
          prefs.getStringList(_favoriteAlbumsKey) ?? const [];

      listeningHistory = rawSongs
          .map((raw) => jsonDecode(raw))
          .whereType<Map<String, dynamic>>()
          .map(Song.fromJson)
          .where((song) =>
              song.id.trim().isNotEmpty && _isSupportedSongSource(song))
          .toList();
      searchHistory = rawSearches
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .take(_maxSearchHistory)
          .toList();
      favoriteSongs = rawFavorites
          .map((raw) => jsonDecode(raw))
          .whereType<Map<String, dynamic>>()
          .map(Song.fromJson)
          .where((song) =>
              song.id.trim().isNotEmpty && _isSupportedSongSource(song))
          .toList();
      favoriteAlbums = rawFavoriteAlbums
          .map((raw) => jsonDecode(raw))
          .whereType<Map<String, dynamic>>()
          .map(Playlist.fromJson)
          .where((album) => album.id.trim().isNotEmpty)
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _addListeningHistory(Song song) async {
    final cached = _cacheableSong(song);
    final cleanId = _historySongKey(cached);

    listeningHistory = [
      cached,
      ...listeningHistory.where((item) => _historySongKey(item) != cleanId),
    ].take(_maxListeningHistory).toList();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _listeningHistoryKey,
        listeningHistory
            .map((item) => jsonEncode(item.toJson()))
            .toList(growable: false),
      );
    } catch (_) {}
  }

  Future<void> _addSearchHistory(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return;
    }

    final cleanLower = cleanQuery.toLowerCase();
    searchHistory = [
      cleanQuery,
      ...searchHistory.where((item) => item.trim().toLowerCase() != cleanLower),
    ].take(_maxSearchHistory).toList();
    notifyListeners();

    await _saveSearchHistory();
  }

  Future<void> _saveSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_searchHistoryKey, searchHistory);
    } catch (_) {}
  }

  Future<void> _saveFavoriteSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _favoriteSongsKey,
        favoriteSongs
            .map((item) => jsonEncode(_cacheableSong(item).toJson()))
            .toList(growable: false),
      );
    } catch (_) {}
  }

  Future<void> _saveFavoriteAlbums() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _favoriteAlbumsKey,
        favoriteAlbums
            .map((album) => jsonEncode(album.toJson()))
            .toList(growable: false),
      );
    } catch (_) {}
  }

  String _favoriteAlbumKey(Playlist album) {
    final shareId = album.shareId.trim();
    if (album.isShared && shareId.isNotEmpty) {
      return 'shared:$shareId';
    }
    return album.id.trim();
  }

  Song _cacheableSong(Song song) {
    return song.sourceType == 'upload' ? song : song.copyWith(streamUrl: '');
  }

  String _historySongKey(Song song) {
    final sourceKey = '${song.sourceType}:${song.sourceId}'.trim();
    if (song.sourceId.trim().isNotEmpty) {
      return sourceKey;
    }

    if (song.databaseId.trim().isNotEmpty) {
      return song.databaseId.trim();
    }

    return song.id.trim();
  }

  bool _isSupportedSongSource(Song song) {
    final sourceType = song.sourceType.trim();
    return sourceType.isEmpty ||
        sourceType == 'youtube' ||
        sourceType == 'upload';
  }

  String formatDuration(Duration value) {
    final seconds = value.inSeconds;
    final minutes = seconds ~/ 60;
    final remain = seconds % 60;
    return '$minutes:${remain.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _audioStateSub?.cancel();
    _audioPositionSub?.cancel();
    _audioDurationSub?.cancel();
    _audioErrorSub?.cancel();
    _audioCommandSub?.cancel();
    audio.dispose();
    music.close();
    super.dispose();
  }
}
