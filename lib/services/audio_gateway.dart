import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';

abstract class AudioGateway {
  Stream<PlayerState> get playerStateStream;
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  bool get isPlaying;
  Duration get position;
  Duration? get duration;

  Future<void> play(Song song);
  Future<void> pause();
  Future<void> resume();
  Future<void> seek(Duration position);
  Future<void> stop();
  Future<void> dispose();
}

class JustAudioGateway implements AudioGateway {
  final AudioPlayer _player = AudioPlayer();

  @override
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

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
  Future<void> play(Song song) async {
    if (!song.hasStream) {
      throw Exception('Bài hát chưa có streamUrl');
    }

    final uri = Uri.parse(song.streamUrl);

    await _player.setAudioSource(
      AudioSource.uri(
        uri,
        headers: _headersFor(uri),
        tag: MediaItem(
          id: song.id,
          title: song.title,
          artist: song.artist,
          album: song.album.isEmpty ? null : song.album,
          artUri: song.coverUrl.isEmpty ? null : Uri.tryParse(song.coverUrl),
          duration: song.duration == Duration.zero ? null : song.duration,
        ),
      ),
    );

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
    await _player.dispose();
  }

  void _startPlayback() {
    unawaited(_player.play().catchError((Object _) {}));
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
      'accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,'
              'image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;'
              'q=0.9',
      'accept-language': 'en-US,en;q=0.5',
    };
  }
}

final AudioGateway audioGateway = JustAudioGateway();
