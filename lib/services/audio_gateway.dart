// ignore_for_file: experimental_member_use

import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';

abstract class AudioGateway {
  Stream<PlayerState> get playerStateStream;
  Stream<Object> get playbackErrorStream;
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  bool get isPlaying;
  Duration get position;
  Duration? get duration;

  Future<void> play(Song song, {Duration? startAt});
  Future<void> pause();
  Future<void> resume();
  Future<void> seek(Duration position);
  Future<void> stop();
  Future<void> dispose();
}

class JustAudioGateway implements AudioGateway {
  final AudioPlayer _player = AudioPlayer();
  final StreamController<Object> _errorController =
      StreamController<Object>.broadcast();
  late final StreamSubscription<PlaybackEvent> _eventSub;

  JustAudioGateway() {
    _eventSub = _player.playbackEventStream.listen(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        if (!_errorController.isClosed) {
          _errorController.add(error);
        }
      },
    );
  }

  @override
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  @override
  Stream<Object> get playbackErrorStream => _errorController.stream;

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  bool get isPlaying => _player.playing;

  @override
  Duration get position => _player.position;

  @override
  Duration? get duration => _player.duration;

  @override
  Future<void> play(Song song, {Duration? startAt}) async {
    if (song.isYoutube) {
      throw Exception('YouTube is played by YoutubePlayerController');
    }

    if (!song.hasStream) {
      throw Exception('Bài hát chưa có streamUrl');
    }

    final mediaItem = MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album.isEmpty ? null : song.album,
      artUri: song.coverUrl.isEmpty ? null : Uri.tryParse(song.coverUrl),
      duration: song.duration == Duration.zero ? null : song.duration,
    );
    final source = _uriSource(song, mediaItem);

    await _player.setAudioSource(source, initialPosition: startAt);

    _startPlayback();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> resume() async {
    _startPlayback();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> stop() async {
    await _player.stop();
  }

  @override
  Future<void> dispose() async {
    await _eventSub.cancel();
    await _errorController.close();
    await _player.dispose();
  }

  AudioSource _uriSource(Song song, MediaItem mediaItem) {
    final uri = Uri.parse(song.streamUrl);

    return AudioSource.uri(
      uri,
      headers: _headersFor(uri),
      tag: mediaItem,
    );
  }

  void _startPlayback() {
    unawaited(_player.play().catchError((Object error, StackTrace stackTrace) {
      if (!_errorController.isClosed) {
        _errorController.add(error);
      }
    }));
  }

  Map<String, String>? _headersFor(Uri uri) {
    if (!uri.host.endsWith('googlevideo.com') &&
        !uri.host.endsWith('youtube.com')) {
      return null;
    }

    return const {
      'user-agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/96.0.4664.18 Safari/537.36',
      'cookie': 'CONSENT=YES+cb',
      'accept': '*/*',
      'accept-language': 'en-US,en;q=0.5',
    };
  }
}

final AudioGateway audioGateway = JustAudioGateway();
