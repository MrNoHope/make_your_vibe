import 'package:just_audio/just_audio.dart';

class VibeAudioService {
  final AudioPlayer musicPlayer = AudioPlayer();
  final AudioPlayer ambientPlayer = AudioPlayer();

  Future<void> loadMusic(String assetPath) async {
    await musicPlayer.setAsset(assetPath);
    await musicPlayer.setLoopMode(LoopMode.one);
  }

  Future<void> loadAmbient(String assetPath) async {
    await ambientPlayer.setAsset(assetPath);
    await ambientPlayer.setLoopMode(LoopMode.one);
  }

  Future<void> play() async {
    await Future.wait([
      musicPlayer.play(),
      ambientPlayer.play(),
    ]);
  }

  Future<void> pause() async {
    await Future.wait([
      musicPlayer.pause(),
      ambientPlayer.pause(),
    ]);
  }

  Future<void> setMusicVolume(double value) async {
    await musicPlayer.setVolume(value);
  }

  Future<void> setAmbientVolume(double value) async {
    await ambientPlayer.setVolume(value);
  }

  Future<void> dispose() async {
    await musicPlayer.dispose();
    await ambientPlayer.dispose();
  }
}