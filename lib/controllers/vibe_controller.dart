import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/song.dart';
import '../services/audio_gateway.dart';
import '../services/music_gateway.dart';

enum VibeRepeatMode {
  off,
  song,
  songOnce,
}

class VibeController extends ChangeNotifier {
  final MusicGateway music = musicGateway;
  final AudioGateway audio = audioGateway;

  static const _lastSongKey = 'make_your_vibe.last_song';
  static const _listeningHistoryKey = 'make_your_vibe.listening_history';
  static const _searchHistoryKey = 'make_your_vibe.search_history';
  static const _maxListeningHistory = 24;
  static const _maxSearchHistory = 16;

  Song? currentSong;
  List<Song> homeSongs = [];
  List<Song> searchResults = [];
  List<Song> activeQueue = [];
  List<Song> listeningHistory = [];
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
  int currentIndex = 0;
  String errorMessage = '';
  VibeRepeatMode repeatMode = VibeRepeatMode.off;

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
      activeQueue = homeSongs;
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
      activeQueue = searchResults;
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
    bool resetRepeatOnceProgress = true,
  }) async {
    final chosenQueue = queue ?? activeQueue;

    if (chosenQueue.isNotEmpty) {
      activeQueue = chosenQueue;
      final foundIndex = chosenQueue.indexWhere((item) => item.id == song.id);
      currentIndex = foundIndex < 0 ? 0 : foundIndex;
    }

    resolving = true;
    errorMessage = '';
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

    final nextIndex =
        currentIndex + 1 >= activeQueue.length ? 0 : currentIndex + 1;
    currentIndex = nextIndex;
    await playSong(activeQueue[nextIndex], queue: activeQueue);
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
    await playSong(activeQueue[previousIndex], queue: activeQueue);
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
      final cached = song.copyWith(streamUrl: '');
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
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _addListeningHistory(Song song) async {
    final cached = song.copyWith(streamUrl: '');
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
