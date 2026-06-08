import 'package:just_audio/just_audio.dart';

class VibeAudioService {
  final AudioPlayer musicPlayer = AudioPlayer();
  final Map<String, AudioPlayer> _ambientPlayers = {};

  Future<void> loadMusicAsset(String assetPath, {required bool loop}) async {
    if (assetPath.isEmpty) {
      return;
    }

    await musicPlayer.setAsset(assetPath);
    await musicPlayer.setLoopMode(loop ? LoopMode.one : LoopMode.off);
  }

  Future<void> playMusic() async {
    if (musicPlayer.audioSource == null) {
      return;
    }

    await musicPlayer.play();
  }

  Future<void> pauseMusic() async {
    await musicPlayer.pause();
  }

  Future<void> setMusicLoop(bool loop) async {
    await musicPlayer.setLoopMode(loop ? LoopMode.one : LoopMode.off);
  }

  Future<void> setMusicVolume(double value) async {
    await musicPlayer.setVolume(value);
  }

  Future<void> loadAmbient({
    required String id,
    required String assetPath,
    required double volume,
  }) async {
    final player = _ambientPlayers[id] ?? AudioPlayer();
    _ambientPlayers[id] = player;

    await player.setAsset(assetPath);
    await player.setLoopMode(LoopMode.one);
    await player.setVolume(volume);
  }

  Future<void> playAmbient(String id) async {
    final player = _ambientPlayers[id];

    if (player == null) {
      return;
    }

    await player.play();
  }

  Future<void> pauseAmbient(String id) async {
    final player = _ambientPlayers[id];

    if (player == null) {
      return;
    }

    await player.pause();
  }

  Future<void> stopAmbient(String id) async {
    final player = _ambientPlayers[id];

    if (player == null) {
      return;
    }

    await player.stop();
  }

  Future<void> setAmbientVolume(String id, double value) async {
    final player = _ambientPlayers[id];

    if (player == null) {
      return;
    }

    await player.setVolume(value);
  }

  Future<void> pauseAllAmbients() async {
    for (final player in _ambientPlayers.values) {
      await player.pause();
    }
  }

  Future<void> dispose() async {
    await musicPlayer.dispose();

    for (final player in _ambientPlayers.values) {
      await player.dispose();
    }

    _ambientPlayers.clear();
  }
}