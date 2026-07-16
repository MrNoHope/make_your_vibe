import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ambient_layer.dart';

class AmbientAudioGateway extends ChangeNotifier {
  AmbientAudioGateway() {
    unawaited(initialize());
  }
//
  static const _masterVolumeKey = 'ambient.master_volume';

  final Map<String, AudioPlayer> _players = {};
  final Set<String> _loadingIds = {};
  bool _initialized = false;
  double _masterVolume = 0.75;
  String _errorMessage = '';

  List<AmbientLayer> _layers = const [
    AmbientLayer(
      id: 'cricket_sound',
      name: 'Tiếng dế',
      assetPath: 'assets/audio/ambient/cricket_sound.mp3',
      volume: 0.42,
    ),
    AmbientLayer(
      id: 'hard_fire',
      name: 'Lửa lớn',
      assetPath: 'assets/audio/ambient/hard_fire.mp3',
      volume: 0.42,
    ),
    AmbientLayer(
      id: 'hard_rain',
      name: 'Mưa lớn',
      assetPath: 'assets/audio/ambient/hard_rain.mp3',
      volume: 0.48,
    ),
    AmbientLayer(
      id: 'night_cricket_sound',
      name: 'Dế ban đêm',
      assetPath: 'assets/audio/ambient/night_cricket_sound.mp3',
      volume: 0.42,
    ),
    AmbientLayer(
      id: 'ocean_waves',
      name: 'Sóng biển',
      assetPath: 'assets/audio/ambient/ocean_waves.mp3',
      volume: 0.5,
    ),
    AmbientLayer(
      id: 'ocean_waves_smooth',
      name: 'Sóng biển êm',
      assetPath: 'assets/audio/ambient/ocean_waves_smooth.mp3',
      volume: 0.5,
    ),
    AmbientLayer(
      id: 'smooth_brown_noise',
      name: 'Brown noise êm',
      assetPath: 'assets/audio/ambient/smooth_brown_noise.mp3',
      volume: 0.36,
    ),
    AmbientLayer(
      id: 'soft_brown_noise',
      name: 'Brown noise nhẹ',
      assetPath: 'assets/audio/ambient/soft_brown_noise.mp3',
      volume: 0.36,
    ),
    AmbientLayer(
      id: 'soft_fire',
      name: 'Lửa nhẹ',
      assetPath: 'assets/audio/ambient/soft_fire.mp3',
      volume: 0.44,
    ),
    AmbientLayer(
      id: 'soft_rain',
      name: 'Mưa nhẹ',
      assetPath: 'assets/audio/ambient/soft_rain.mp3',
      volume: 0.52,
    ),
  ];


  List<AmbientLayer> get layers => List.unmodifiable(_layers);

  double get masterVolume => _masterVolume;

  String get errorMessage => _errorMessage;

  bool get initialized => _initialized;

  bool isLoading(String id) => _loadingIds.contains(id);

  int get activeCount => _layers.where((layer) => layer.active).length;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    _masterVolume = prefs.getDouble(_masterVolumeKey) ?? _masterVolume;
    _layers = _layers.map((layer) {
      return layer.copyWith(
        volume: prefs.getDouble(_volumeKey(layer.id)) ?? layer.volume,
        active: false,
      );
    }).toList(growable: false);
    _initialized = true;
    notifyListeners();
  }

  Future<void> toggleLayer(String id) async {
    await initialize();
    final layer = _layerById(id);
    await setLayerActive(id, !layer.active);
  }

  Future<void> setLayerActive(String id, bool active) async {
    await initialize();
    final layer = _layerById(id).copyWith(active: active);
    _replaceLayer(layer);
    await _persistLayer(layer);

    if (active) {
      await _syncLayer(layer);
    } else {
      await _players[id]?.pause();
    }
  }

  Future<void> setLayerVolume(String id, double volume) async {
    await initialize();
    final clamped = volume.clamp(0.0, 1.0).toDouble();
    final layer = _layerById(id).copyWith(volume: clamped);
    _replaceLayer(layer);
    await _persistLayer(layer);
    await _players[id]?.setVolume(clamped * _masterVolume);
  }

  Future<void> setMasterVolume(double volume) async {
    await initialize();
    _masterVolume = volume.clamp(0.0, 1.0).toDouble();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_masterVolumeKey, _masterVolume);

    for (final layer in _layers) {
      await _players[layer.id]?.setVolume(layer.volume * _masterVolume);
    }
  }

  Future<void> stopAll() async {
    await initialize();
    _layers = [
      for (final layer in _layers) layer.copyWith(active: false),
    ];
    notifyListeners();

    for (final layer in _layers) {
      await _players[layer.id]?.pause();
    }
  }

  AmbientLayer _layerById(String id) {
    return _layers.firstWhere((layer) => layer.id == id);
  }

  void _replaceLayer(AmbientLayer layer) {
    _layers = [
      for (final current in _layers)
        if (current.id == layer.id) layer else current,
    ];
    notifyListeners();
  }

  Future<void> _syncLayer(AmbientLayer layer) async {
    _loadingIds.add(layer.id);
    _errorMessage = '';
    notifyListeners();

    try {
      final player = _players[layer.id] ??= AudioPlayer(
        handleInterruptions: false,
        androidApplyAudioAttributes: false,
        handleAudioSessionActivation: false,
      );

      if (player.sequence.isEmpty) {
        await player.setAsset(layer.assetPath);
        await player.setLoopMode(LoopMode.one);
      }

      await player.setVolume(layer.volume * _masterVolume);
      unawaited(_playLayer(player, layer));
    } catch (error) {
      _errorMessage = 'Ambient error: $error';
      final failed = layer.copyWith(active: false);
      _replaceLayer(failed);
      await _persistLayer(failed);
    } finally {
      _loadingIds.remove(layer.id);
      notifyListeners();
    }
  }

  Future<void> _playLayer(AudioPlayer player, AmbientLayer layer) async {
    try {
      await player.play();
    } catch (error) {
      _errorMessage = 'Ambient error: $error';
      final failed = _layerById(layer.id).copyWith(active: false);
      _replaceLayer(failed);
      await _persistLayer(failed);
    }
  }

  Future<void> _persistLayer(AmbientLayer layer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volumeKey(layer.id), layer.volume);
  }

  static String _volumeKey(String id) => 'ambient.$id.volume';
}

final AmbientAudioGateway ambientAudioGateway = AmbientAudioGateway();
