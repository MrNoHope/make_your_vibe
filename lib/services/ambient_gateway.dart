import 'dart:async';

import 'package:just_audio/just_audio.dart';

class AmbientItem {
  const AmbientItem(this.id, this.vi, this.en, this.asset, this.icon);

  final String id;
  final String vi;
  final String en;
  final String asset;
  final String icon;
}

class AmbientGateway {
  static const items = [
    AmbientItem(
      'cricket_sound',
      'Tiếng dế',
      'Cricket sound',
      'assets/audio/ambient/cricket_sound.mp3',
      '🦗',
    ),
    AmbientItem(
      'hard_fire',
      'Lửa lớn',
      'Hard fire',
      'assets/audio/ambient/hard_fire.mp3',
      '🔥',
    ),
    AmbientItem(
      'hard_rain',
      'Mưa lớn',
      'Hard rain',
      'assets/audio/ambient/hard_rain.mp3',
      '⛈️',
    ),
    AmbientItem(
      'night_cricket_sound',
      'Dế ban đêm',
      'Night cricket sound',
      'assets/audio/ambient/night_cricket_sound.mp3',
      '🌙',
    ),
    AmbientItem(
      'ocean_waves',
      'Sóng biển',
      'Ocean waves',
      'assets/audio/ambient/ocean_waves.mp3',
      '🌊',
    ),
    AmbientItem(
      'ocean_waves_smooth',
      'Sóng biển êm',
      'Smooth ocean waves',
      'assets/audio/ambient/ocean_waves_smooth.mp3',
      '🏝️',
    ),
    AmbientItem(
      'smooth_brown_noise',
      'Brown noise êm',
      'Smooth brown noise',
      'assets/audio/ambient/smooth_brown_noise.mp3',
      '🎧',
    ),
    AmbientItem(
      'soft_brown_noise',
      'Brown noise nhẹ',
      'Soft brown noise',
      'assets/audio/ambient/soft_brown_noise.mp3',
      '🟤',
    ),
    AmbientItem(
      'soft_fire',
      'Lửa nhẹ',
      'Soft fire',
      'assets/audio/ambient/soft_fire.mp3',
      '🪵',
    ),
    AmbientItem(
      'soft_rain',
      'Mưa nhẹ',
      'Soft rain',
      'assets/audio/ambient/soft_rain.mp3',
      '🌧️',
    ),
  ];

  final Map<String, AudioPlayer> _players = {};
  final Set<String> _loaded = {};
  final Map<String, Future<void>> _loading = {};
  final Map<String, double> levels = {
    for (final item in items) item.id: 0,
  };

  void Function(bool active)? onActivityChanged;
  double masterVolume = 0.8;

  bool get isActive =>
      masterVolume > 0 && levels.values.any((value) => value > 0);

  Future<void> setLevel(String id, double level) async {
    if (!levels.containsKey(id)) return;
    final safeLevel = level.clamp(0.0, 1.0).toDouble();
    levels[id] = safeLevel;
    var player = _players[id];
    if (safeLevel <= 0) {
      if (player != null) await player.pause();
      _notifyActivity();
      return;
    }

    player ??= AudioPlayer();
    _players[id] = player;
    final activePlayer = player;
    if (!_loaded.contains(id)) {
      final task = _loading.putIfAbsent(id, () async {
        final item = items.firstWhere((entry) => entry.id == id);
        await activePlayer
            .setAudioSource(AudioSource.asset(item.asset), preload: true)
            .timeout(const Duration(seconds: 10));
        await activePlayer.setLoopMode(LoopMode.one);
        _loaded.add(id);
      });
      try {
        await task;
      } finally {
        _loading.remove(id);
      }
    }

    final currentLevel = levels[id] ?? 0;
    await activePlayer.setVolume(currentLevel * masterVolume);
    if (currentLevel <= 0 || masterVolume <= 0) {
      await activePlayer.pause();
    } else if (!activePlayer.playing) {
      unawaited(activePlayer.play());
    }
    _notifyActivity();
  }

  Future<void> setMaster(double value) async {
    masterVolume = value.clamp(0.0, 1.0).toDouble();
    for (final item in items) {
      final player = _players[item.id];
      final level = levels[item.id] ?? 0;
      if (player == null || level <= 0) continue;
      await player.setVolume(level * masterVolume);
      if (masterVolume <= 0) {
        await player.pause();
      } else if (!player.playing) {
        unawaited(player.play());
      }
    }
    _notifyActivity();
  }

  Future<void> apply(
    Map<String, double> values, {
    double master = 0.8,
  }) async {
    await setMaster(master);
    for (final item in items) {
      await setLevel(item.id, values[item.id] ?? 0);
    }
    _notifyActivity();
  }

  Future<void> stopAll() async {
    for (final id in levels.keys.toList()) {
      levels[id] = 0;
      final player = _players[id];
      if (player != null) await player.pause();
    }
    _notifyActivity();
  }

  void _notifyActivity() => onActivityChanged?.call(isActive);

  Future<void> dispose() async {
    for (final player in _players.values) {
      await player.dispose();
    }
  }
}
