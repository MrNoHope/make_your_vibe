import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart' as ja;

import '../models/song.dart';
import 'background_audio_gateway.dart';

enum AudioGatewayCommand {
  previous,
  next,
}

abstract class AudioGateway {
  Stream<ja.PlayerState> get playerStateStream;
  Stream<Object> get playbackErrorStream;
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<AudioGatewayCommand> get commandStream;
  bool get isPlaying;
  Duration get position;
  Duration? get duration;

  Future<void> initialize();
  Future<void> play(Song song, {Duration? startAt});
  Future<void> pause();
  Future<void> resume();
  Future<void> seek(Duration position);
  Future<void> stop();
  Future<void> dispose();
}

class JustAudioGateway implements AudioGateway {
  JustAudioGateway() : _handler = MakeYourVibeAudioHandler();

  final MakeYourVibeAudioHandler _handler;
  Future<void>? _initializeFuture;

  @override
  Stream<ja.PlayerState> get playerStateStream => _handler.playerStateStream;

  @override
  Stream<Object> get playbackErrorStream => _handler.playbackErrorStream;

  @override
  Stream<Duration> get positionStream => _handler.positionStream;

  @override
  Stream<Duration?> get durationStream => _handler.durationStream;

  @override
  Stream<AudioGatewayCommand> get commandStream => _handler.commandStream;

  @override
  bool get isPlaying => _handler.isPlaying;

  @override
  Duration get position => _handler.position;

  @override
  Duration? get duration => _handler.duration;

  @override
  Future<void> initialize() {
    return _initializeFuture ??= AudioService.init(
      builder: () => _handler,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.make_your_vibe.player',
        androidNotificationChannelName: 'Make Your Vibe Player',
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidNotificationOngoing: true,
        androidShowNotificationBadge: false,
        androidStopForegroundOnPause: true,
      ),
    );
  }

  @override
  Future<void> play(Song song, {Duration? startAt}) async {
    await initialize();
    if (!song.hasStream) {
      throw Exception('Bai hat chua co streamUrl');
    }

    await _handler.playSong(song, startAt: startAt);
  }

  @override
  Future<void> pause() => _handler.pause();

  @override
  Future<void> resume() => _handler.play();

  @override
  Future<void> seek(Duration position) => _handler.seek(position);

  @override
  Future<void> stop() => _handler.stop();

  @override
  Future<void> dispose() => _handler.dispose();
}

class MakeYourVibeAudioHandler extends BaseAudioHandler with SeekHandler {
  MakeYourVibeAudioHandler() {
    _eventSub = _player.playbackEventStream.listen(
      (_) => _broadcastState(),
      onError: (Object error, StackTrace stackTrace) {
        if (!_errorController.isClosed) {
          _errorController.add(error);
        }
        _broadcastError(error);
      },
    );
    _playerStateSub = _player.playerStateStream.listen((_) {
      _broadcastState();
    });
  }

  static const _previousSeekThreshold = Duration(seconds: 3);

  final ja.AudioPlayer _player = ja.AudioPlayer();
  final StreamController<Object> _errorController =
      StreamController<Object>.broadcast();
  final StreamController<AudioGatewayCommand> _commandController =
      StreamController<AudioGatewayCommand>.broadcast();

  late final StreamSubscription<ja.PlaybackEvent> _eventSub;
  late final StreamSubscription<ja.PlayerState> _playerStateSub;

  Stream<ja.PlayerState> get playerStateStream => _player.playerStateStream;

  Stream<Object> get playbackErrorStream => _errorController.stream;

  Stream<Duration> get positionStream => _player.positionStream;

  Stream<Duration?> get durationStream => _player.durationStream;

  Stream<AudioGatewayCommand> get commandStream => _commandController.stream;

  bool get isPlaying => _player.playing;

  Duration get position => _player.position;

  Duration? get duration => _player.duration;

  Future<void> playSong(Song song, {Duration? startAt}) async {
    final item = MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album.isEmpty ? null : song.album,
      artUri: song.coverUrl.isEmpty ? null : Uri.tryParse(song.coverUrl),
      duration: song.duration == Duration.zero ? null : song.duration,
    );
    final source = ja.AudioSource.uri(
      Uri.parse(song.streamUrl),
    );

    mediaItem.add(item);
    queue.add([item]);
    await backgroundAudioGateway.preparePlayback();
    await _player.setAudioSource(source, initialPosition: startAt);
    await play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    await backgroundAudioGateway.releasePlayback();
    _broadcastState();
  }

  @override
  Future<void> play() async {
    await backgroundAudioGateway.preparePlayback();
    _startPlayback();
    _broadcastState();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position.isNegative ? Duration.zero : position);
    _broadcastState();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position > _previousSeekThreshold) {
      await seek(Duration.zero);
      return;
    }

    if (!_commandController.isClosed) {
      _commandController.add(AudioGatewayCommand.previous);
    }
  }

  @override
  Future<void> skipToNext() async {
    if (!_commandController.isClosed) {
      _commandController.add(AudioGatewayCommand.next);
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await backgroundAudioGateway.releasePlayback();
    mediaItem.add(null);
    queue.add(const []);
    playbackState.add(PlaybackState());
  }

  Future<void> dispose() async {
    await _eventSub.cancel();
    await _playerStateSub.cancel();
    await _commandController.close();
    await _errorController.close();
    await backgroundAudioGateway.releasePlayback();
    await _player.dispose();
  }

  void _startPlayback() {
    unawaited(_player.play().catchError((Object error, StackTrace stackTrace) {
      if (!_errorController.isClosed) {
        _errorController.add(error);
      }
    }));
  }

  void _broadcastState() {
    final playerState = _player.playerState;
    final playing = playerState.playing;
    final controls = [
      MediaControl.skipToPrevious,
      if (playing) MediaControl.pause else MediaControl.play,
      MediaControl.skipToNext,
    ];

    playbackState.add(
      PlaybackState(
        controls: controls,
        androidCompactActionIndices: const [0, 1, 2],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        processingState: _audioProcessingState(playerState.processingState),
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ),
    );
  }

  void _broadcastError(Object error) {
    playbackState.add(
      PlaybackState(
        controls: const [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.skipToNext,
        ],
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.error,
        playing: false,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        errorMessage: '$error',
      ),
    );
  }

  AudioProcessingState _audioProcessingState(ja.ProcessingState state) {
    return switch (state) {
      ja.ProcessingState.idle => AudioProcessingState.idle,
      ja.ProcessingState.loading => AudioProcessingState.loading,
      ja.ProcessingState.buffering => AudioProcessingState.buffering,
      ja.ProcessingState.ready => AudioProcessingState.ready,
      ja.ProcessingState.completed => AudioProcessingState.completed,
    };
  }
}

final AudioGateway audioGateway = JustAudioGateway();
