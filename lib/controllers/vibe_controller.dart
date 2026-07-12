import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as yt;

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
  yt.YoutubePlayerController? youtubeController;
  static const _lastSongKey = 'make_your_vibe.last_song';
  static const _youtubeParams = yt.YoutubePlayerParams(
    enableCaption: false,
    enableKeyboard: false,
    mute: false,
    pointerEvents: yt.PointerEvents.none,
    showControls: false,
    showFullscreenButton: false,
    showVideoAnnotations: false,
    strictRelatedVideos: true,
    videoStateUpdateInterval: 500,
  );

  Song? currentSong;
  List<Song> homeSongs = [];
  List<Song> searchResults = [];
  List<Song> activeQueue = [];

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
  bool _youtubeEndedHandled = false;
  int currentIndex = 0;
  String errorMessage = '';
  VibeRepeatMode repeatMode = VibeRepeatMode.off;

  StreamSubscription<ja.PlayerState>? _audioStateSub;
  StreamSubscription<Duration>? _audioPositionSub;
  StreamSubscription<Duration?>? _audioDurationSub;
  StreamSubscription<Object>? _audioErrorSub;
  StreamSubscription<yt.YoutubePlayerValue>? _youtubeStateSub;
  StreamSubscription<yt.YoutubeVideoState>? _youtubePositionSub;

  VibeController() {
    _audioStateSub = audio.playerStateStream.listen((state) {
      if (currentSong?.isYoutube == true) {
        return;
      }

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
      if (currentSong?.isYoutube == true) {
        return;
      }

      position = value;
      notifyListeners();
    });
    _audioDurationSub = audio.durationStream.listen((value) {
      if (currentSong?.isYoutube == true) {
        return;
      }

      duration = value;
      notifyListeners();
    });
    _audioErrorSub = audio.playbackErrorStream.listen((error) {
      if (currentSong?.isYoutube == true) {
        return;
      }

      resolving = false;
      isPlaying = false;
      errorMessage = 'Khong phat duoc bai nay: $error';
      notifyListeners();
    });
    unawaited(_restoreLastSong());
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

    if (song.isYoutube) {
      await _playYoutubeSong(song);
      return;
    }

    try {
      await _disposeYoutubeController();
      await audio.stop();
      final playableSong = await music.resolveStream(song);
      currentSong = playableSong;
      duration =
          playableSong.duration == Duration.zero ? null : playableSong.duration;
      await audio.play(playableSong);
      _playRequested = true;
      isPlaying = true;

      unawaited(_saveLastSong(playableSong));
    } catch (error) {
      errorMessage = 'Khong phat duoc bai nay: $error';
      _playRequested = false;
      isPlaying = false;
    }

    resolving = false;
    notifyListeners();
  }

  Future<void> _playYoutubeSong(
    Song song, {
    Duration startAt = Duration.zero,
  }) async {
    final videoId = song.youtubeVideoId.trim();

    if (!_isYoutubeVideoId(videoId)) {
      errorMessage = 'Video YouTube khong hop le: $videoId';
      _playRequested = false;
      isPlaying = false;
      resolving = false;
      notifyListeners();
      return;
    }

    final playableSong = song.copyWith(
      streamUrl: 'youtube:$videoId',
      sourceType: 'youtube',
      sourceId: videoId,
    );
    final startSeconds = startAt.inMilliseconds / 1000;

    try {
      await audio.stop();
      _youtubeEndedHandled = false;
      currentSong = playableSong;
      duration = playableSong.duration == Duration.zero
          ? duration
          : playableSong.duration;

      final existingController = youtubeController;

      if (existingController == null) {
        final controller = yt.YoutubePlayerController.fromVideoId(
          videoId: videoId,
          autoPlay: true,
          startSeconds: startSeconds > 0 ? startSeconds : null,
          params: _youtubeParams,
        );
        youtubeController = controller;
        _attachYoutubeController(controller);
      } else {
        await existingController.loadVideoById(
          videoId: videoId,
          startSeconds: startSeconds > 0 ? startSeconds : null,
        );
        unawaited(existingController.playVideo());
      }

      position = startAt;
      _playRequested = true;
      isPlaying = true;
      resolving = false;
      unawaited(_saveLastSong(playableSong));
    } catch (error) {
      errorMessage = 'Khong phat duoc bai nay: $error';
      _playRequested = false;
      isPlaying = false;
      resolving = false;
    }

    notifyListeners();
  }

  void _attachYoutubeController(yt.YoutubePlayerController controller) {
    _youtubeStateSub?.cancel();
    _youtubePositionSub?.cancel();

    _youtubeStateSub = controller.stream.listen((value) {
      if (currentSong?.isYoutube != true) {
        return;
      }

      if (value.hasError) {
        resolving = false;
        isPlaying = false;
        _playRequested = false;
        errorMessage = 'YouTube khong cho phat bai nay (${value.error.code})';
        notifyListeners();
        return;
      }

      final metaDuration = value.metaData.duration;
      if (metaDuration > Duration.zero) {
        duration = metaDuration;
      }

      switch (value.playerState) {
        case yt.PlayerState.playing:
          resolving = false;
          isPlaying = true;
          _playRequested = true;
          _youtubeEndedHandled = false;
        case yt.PlayerState.buffering:
          isPlaying = _playRequested;
        case yt.PlayerState.paused:
          resolving = false;
          isPlaying = false;
          _playRequested = false;
        case yt.PlayerState.ended:
          resolving = false;
          isPlaying = false;
          _playRequested = false;
          if (!_youtubeEndedHandled && !_handlingCompletion && !_seeking) {
            _youtubeEndedHandled = true;
            unawaited(_handleSongCompleted());
          }
        case yt.PlayerState.cued:
        case yt.PlayerState.unStarted:
        case yt.PlayerState.unknown:
          break;
      }

      notifyListeners();
    });

    _youtubePositionSub = controller.videoStateStream.listen((state) {
      if (currentSong?.isYoutube != true || _seeking) {
        return;
      }

      position = state.position;
      notifyListeners();
    });
  }

  Future<void> togglePlay() async {
    final song = currentSong;

    if (song == null) {
      if (activeQueue.isNotEmpty) {
        await playSong(activeQueue.first, queue: activeQueue);
      }
      return;
    }

    if (song.isYoutube) {
      final controller = youtubeController;

      if (controller == null) {
        await playSong(song, queue: activeQueue.isEmpty ? [song] : activeQueue);
        return;
      }

      if (isPlaying || _playRequested) {
        _playRequested = false;
        isPlaying = false;
        await controller.pauseVideo();
      } else {
        _playRequested = true;
        isPlaying = true;
        await controller.playVideo();
      }

      notifyListeners();
      return;
    }

    if (song.hasStream) {
      if (audio.isPlaying) {
        _playRequested = false;
        await audio.pause();
        isPlaying = false;
      } else {
        _playRequested = true;
        await audio.resume();
        isPlaying = true;
      }
    } else {
      await playSong(song, queue: activeQueue.isEmpty ? [song] : activeQueue);
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
    final isYoutube = song?.isYoutube == true;
    final shouldResume = isYoutube
        ? (_playRequested || isPlaying)
        : (_playRequested || audio.isPlaying || isPlaying);

    _seeking = true;
    errorMessage = '';

    try {
      if (isYoutube && song != null) {
        position = targetPosition;
        notifyListeners();

        final controller = youtubeController;

        if (controller == null) {
          final sourceSong =
              activeQueue.isNotEmpty && currentIndex < activeQueue.length
                  ? activeQueue[currentIndex]
                  : song;
          await _playYoutubeSong(sourceSong, startAt: targetPosition);
          return;
        }

        await controller.seekTo(
          seconds: targetPosition.inMilliseconds / 1000,
          allowSeekAhead: true,
        );

        if (shouldResume) {
          _playRequested = true;
          isPlaying = true;
          await controller.playVideo();
        } else {
          _playRequested = false;
          isPlaying = false;
          await controller.pauseVideo();
        }
      } else {
        await audio.seek(targetPosition);
      }
    } catch (error) {
      errorMessage = 'Khong tua duoc bai nay: $error';
      _playRequested = false;
      isPlaying = false;
    } finally {
      _seeking = false;
      resolving = false;
    }
    position = targetPosition;

    if (shouldResume && song != null && !isYoutube && errorMessage.isEmpty) {
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

      if (!_playRequested || currentSong == null || currentSong!.isYoutube) {
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

  Future<void> _disposeYoutubeController() async {
    final controller = youtubeController;
    youtubeController = null;
    _youtubeEndedHandled = false;
    await _youtubeStateSub?.cancel();
    await _youtubePositionSub?.cancel();
    _youtubeStateSub = null;
    _youtubePositionSub = null;

    if (controller != null) {
      await controller.close();
    }
  }

  Future<void> reset() async {
    await _disposeYoutubeController();
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

      currentSong = Song.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      duration =
          currentSong?.duration == Duration.zero ? null : currentSong?.duration;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveLastSong(Song song) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached =
          song.copyWith(streamUrl: song.isYoutube ? '' : song.streamUrl);
      await prefs.setString(_lastSongKey, jsonEncode(cached.toJson()));
    } catch (_) {}
  }

  Future<void> _clearLastSong() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastSongKey);
    } catch (_) {}
  }

  String formatDuration(Duration value) {
    final seconds = value.inSeconds;
    final minutes = seconds ~/ 60;
    final remain = seconds % 60;
    return '$minutes:${remain.toString().padLeft(2, '0')}';
  }

  bool _isYoutubeVideoId(String value) {
    return RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(value);
  }

  @override
  void dispose() {
    _audioStateSub?.cancel();
    _audioPositionSub?.cancel();
    _audioDurationSub?.cancel();
    _audioErrorSub?.cancel();
    _youtubeStateSub?.cancel();
    _youtubePositionSub?.cancel();
    unawaited(youtubeController?.close());
    audio.dispose();
    music.close();
    super.dispose();
  }
}
