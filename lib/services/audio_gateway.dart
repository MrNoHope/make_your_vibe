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

    await _player.setAudioSource(
      AudioSource.uri(
        Uri.parse(song.streamUrl),
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

    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> resume() async {
    await _player.play();
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
}

final AudioGateway audioGateway = JustAudioGateway();
