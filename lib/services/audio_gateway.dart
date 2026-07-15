import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

import '../models/models.dart';

class AudioGateway extends BaseAudioHandler with SeekHandler {
  AudioGateway();

  AudioPlayer _activePlayer = AudioPlayer();
  AudioPlayer _standbyPlayer = AudioPlayer();

  final StreamController<PlayerState> _playerStateController =
      StreamController<PlayerState>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durationController =
      StreamController<Duration?>.broadcast();
  final StreamController<Duration> _bufferedPositionController =
      StreamController<Duration>.broadcast();
  final StreamController<ProcessingState> _processingController =
      StreamController<ProcessingState>.broadcast();

  StreamSubscription<PlaybackEvent>? _eventSubscription;
  StreamSubscription<PlayerException>? _errorSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<Duration>? _bufferedSubscription;
  StreamSubscription<ProcessingState>? _processingSubscription;

  Song? loadedSong;
  Future<void> Function()? onNext;
  Future<void> Function()? onPrevious;
  Future<void> Function()? onTaskRemovedCallback;
  void Function(String message)? onError;

  bool _ambientActive = false;
  int _latestLoadRequest = 0;
  bool _stopping = false;
  int _standbyGeneration = 0;
  String _preloadedSongId = '';
  String _preloadedStreamUrl = '';

  Stream<PlayerState> get playerStateStream => _playerStateController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration?> get durationStream => _durationController.stream;
  Stream<Duration> get bufferedPositionStream =>
      _bufferedPositionController.stream;
  Stream<ProcessingState> get processingStateStream =>
      _processingController.stream;

  bool get playing => _activePlayer.playing;
  Duration get position => _activePlayer.position;
  Duration? get duration => _activePlayer.duration;

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    await _wireActivePlayer();
  }

  Future<bool> loadAndPlay(
    Song song, {
    required int requestId,
  }) async {
    if (song.source == SongSource.local && song.localPath.isEmpty) {
      throw Exception('Không tìm thấy file nhạc trong thiết bị.');
    }
    if (song.source == SongSource.youtube && song.streamUrl.isEmpty) {
      throw Exception('Đường dẫn phát nhạc đang trống.');
    }

    if (requestId < _latestLoadRequest) return false;
    _latestLoadRequest = requestId;

    final item = MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      artUri: song.artworkUrl.startsWith('http')
          ? Uri.tryParse(song.artworkUrl)
          : song.artworkUrl.isNotEmpty
              ? Uri.file(song.artworkUrl)
              : null,
      duration: song.durationMs > 0 ? song.duration : null,
    );

    final source = song.source == SongSource.local
        ? AudioSource.file(song.localPath, tag: item)
        : AudioSource.uri(Uri.parse(song.streamUrl), tag: item);

    final target = _standbyPlayer;
    final generation = ++_standbyGeneration;
    final alreadyPrepared = _preloadedSongId == song.id &&
        _preloadedStreamUrl == song.streamUrl &&
        target.processingState == ProcessingState.ready;
    if (!alreadyPrepared) {
      await target
          .setAudioSource(source, preload: true)
          .timeout(const Duration(seconds: 11));
    }

    if (requestId != _latestLoadRequest ||
        generation != _standbyGeneration ||
        target != _standbyPlayer) {
      return false;
    }

    final oldPlayer = _activePlayer;
    await oldPlayer.pause();
    _activePlayer = target;
    _standbyPlayer = oldPlayer;
    loadedSong = song;
    _preloadedSongId = '';
    _preloadedStreamUrl = '';
    mediaItem.add(item);

    await _wireActivePlayer();
    _startPlayback();
    unawaited(_standbyPlayer.stop());
    return true;
  }


  Future<void> preload(Song song) async {
    if (song.source == SongSource.local && song.localPath.isEmpty) return;
    if (song.source == SongSource.youtube && song.streamUrl.isEmpty) return;

    final item = MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      artUri: song.artworkUrl.startsWith('http')
          ? Uri.tryParse(song.artworkUrl)
          : song.artworkUrl.isNotEmpty
              ? Uri.file(song.artworkUrl)
              : null,
      duration: song.durationMs > 0 ? song.duration : null,
    );
    final source = song.source == SongSource.local
        ? AudioSource.file(song.localPath, tag: item)
        : AudioSource.uri(Uri.parse(song.streamUrl), tag: item);
    final target = _standbyPlayer;
    final generation = ++_standbyGeneration;
    try {
      await target
          .setAudioSource(source, preload: true)
          .timeout(const Duration(seconds: 10));
      if (generation != _standbyGeneration || target != _standbyPlayer) return;
      _preloadedSongId = song.id;
      _preloadedStreamUrl = song.streamUrl;
    } catch (_) {
      if (generation == _standbyGeneration) {
        _preloadedSongId = '';
        _preloadedStreamUrl = '';
      }
    }
  }

  Future<void> _wireActivePlayer() async {
    await _eventSubscription?.cancel();
    await _errorSubscription?.cancel();
    await _stateSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _bufferedSubscription?.cancel();
    await _processingSubscription?.cancel();

    _eventSubscription = _activePlayer.playbackEventStream.listen(
      _broadcastState,
      onError: (Object error, StackTrace stackTrace) {
        onError?.call('Không thể phát luồng âm thanh.');
      },
    );
    _errorSubscription = _activePlayer.errorStream.listen((error) {
      onError?.call(error.message ?? 'Không thể phát âm thanh.');
      _publishPlaybackState();
    });
    _stateSubscription = _activePlayer.playerStateStream.listen(
      _playerStateController.add,
    );
    _positionSubscription = _activePlayer.positionStream.listen(
      _positionController.add,
    );
    _durationSubscription = _activePlayer.durationStream.listen(
      _durationController.add,
    );
    _bufferedSubscription = _activePlayer.bufferedPositionStream.listen(
      _bufferedPositionController.add,
    );
    _processingSubscription = _activePlayer.processingStateStream.listen(
      _processingController.add,
    );

    _playerStateController.add(
      PlayerState(_activePlayer.playing, _activePlayer.processingState),
    );
    _positionController.add(_activePlayer.position);
    _durationController.add(_activePlayer.duration);
    _bufferedPositionController.add(_activePlayer.bufferedPosition);
    _processingController.add(_activePlayer.processingState);
    _publishPlaybackState();
  }

  void _startPlayback() {
    unawaited(
      _activePlayer.play().catchError((Object error, StackTrace stackTrace) {
        onError?.call('Không thể bắt đầu phát bài hát.');
      }),
    );
  }

  Future<void> toggle() async {
    if (_activePlayer.playing) {
      await pause();
      return;
    }
    await play();
  }

  @override
  Future<void> play() async {
    if (loadedSong == null) return;
    if (_activePlayer.processingState == ProcessingState.completed) {
      await _activePlayer.seek(Duration.zero);
    }
    _startPlayback();
  }

  @override
  Future<void> pause() => _activePlayer.pause();

  @override
  Future<void> seek(Duration position) => _activePlayer.seek(position);

  @override
  Future<void> skipToNext() async {
    if (onNext != null) await onNext!();
  }

  @override
  Future<void> skipToPrevious() async {
    if (onPrevious != null) await onPrevious!();
  }

  Future<void> setAmbientActive(bool active) async {
    if (_ambientActive == active) return;
    _ambientActive = active;
    if (active && loadedSong == null) {
      mediaItem.add(
        MediaItem(
          id: 'ambient_mixer',
          title: 'Ambient Mixer',
          artist: 'Make Your Vibe',
        ),
      );
    } else if (!active && loadedSong == null) {
      mediaItem.add(null);
    }
    _publishPlaybackState();
  }

  @override
  Future<void> onTaskRemoved() => stop();

  @override
  Future<void> stop() async {
    if (_stopping) return;
    _stopping = true;
    try {
      _latestLoadRequest += 1;
      _standbyGeneration += 1;
      _preloadedSongId = '';
      _preloadedStreamUrl = '';
      await onTaskRemovedCallback?.call();
      await Future.wait([
        _activePlayer.stop(),
        _standbyPlayer.stop(),
      ]);
      _ambientActive = false;
      _publishPlaybackState(forceIdle: true);
      await super.stop();
    } finally {
      _stopping = false;
    }
  }

  Future<void> reset() async {
    await stop();
    mediaItem.add(null);
    loadedSong = null;
  }

  void _broadcastState(PlaybackEvent event) {
    _publishPlaybackState(queueIndex: event.currentIndex);
  }

  void _publishPlaybackState({int? queueIndex, bool forceIdle = false}) {
    final musicPlaying = _activePlayer.playing;
    final effectivePlaying = musicPlaying || _ambientActive;
    var state = _mapProcessingState(_activePlayer.processingState);
    if (forceIdle) {
      state = AudioProcessingState.idle;
    } else if (_ambientActive && state == AudioProcessingState.idle) {
      state = AudioProcessingState.ready;
    }

    playbackState.add(
      PlaybackState(
        controls: [
          if (loadedSong != null) MediaControl.skipToPrevious,
          if (loadedSong != null)
            musicPlaying ? MediaControl.pause : MediaControl.play,
          if (loadedSong != null) MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: loadedSong == null
            ? const {}
            : const {
                MediaAction.seek,
                MediaAction.seekForward,
                MediaAction.seekBackward,
              },
        androidCompactActionIndices: loadedSong == null
            ? const [0]
            : const [0, 1, 2],
        processingState: state,
        playing: effectivePlaying,
        updatePosition: _activePlayer.position,
        bufferedPosition: _activePlayer.bufferedPosition,
        speed: _activePlayer.speed,
        queueIndex: queueIndex,
      ),
    );
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  Future<void> disposePlayer() async {
    await _eventSubscription?.cancel();
    await _errorSubscription?.cancel();
    await _stateSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _bufferedSubscription?.cancel();
    await _processingSubscription?.cancel();
    await _activePlayer.dispose();
    await _standbyPlayer.dispose();
    await _playerStateController.close();
    await _positionController.close();
    await _durationController.close();
    await _bufferedPositionController.close();
    await _processingController.close();
  }
}
