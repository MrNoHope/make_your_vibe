import 'package:flutter/material.dart';

import '../../../data/models/ambient_sound.dart';
import '../../../data/models/music_track.dart';
import '../../../data/models/vibe_preset.dart';
import '../../../data/repositories/vibe_repository.dart';
import '../services/vibe_audio_service.dart';

class VibePlayerController extends ChangeNotifier {
  final VibeRepository _repository = VibeRepository();
  final VibeAudioService _audioService = VibeAudioService();

  late final MusicTrack currentTrack;
  late final List<VibePreset> presets;
  late final List<AmbientSound> ambientSounds;

  int selectedPresetIndex = 0;
  bool isPlaying = false;
  bool isMusicLoopEnabled = false;
  String? audioError;

  double musicVolume = 0.7;
  double defaultAmbientVolume = 0.45;

  final Set<String> activeAmbientIds = {};
  final Map<String, double> ambientVolumes = {};

  VibePlayerController() {
    currentTrack = _repository.defaultTrack;
    presets = _repository.getPresets();
    ambientSounds = _repository.getAmbientSounds();

    musicVolume = selectedPreset.musicVolume;
    defaultAmbientVolume = selectedPreset.ambientVolume;

    for (final sound in ambientSounds) {
      ambientVolumes[sound.id] = defaultAmbientVolume;
    }
  }

  VibePreset get selectedPreset {
    return presets[selectedPresetIndex];
  }

  List<AmbientSound> get activeAmbients {
    return ambientSounds
        .where((sound) => activeAmbientIds.contains(sound.id))
        .toList();
  }

  AmbientSound get displayAmbient {
    if (activeAmbients.isNotEmpty) {
      return activeAmbients.first;
    }

    return ambientSounds.first;
  }

  bool isAmbientActive(String id) {
    return activeAmbientIds.contains(id);
  }

  double ambientVolumeOf(String id) {
    return ambientVolumes[id] ?? defaultAmbientVolume;
  }

  String ambientSummary(dynamic language) {
    if (activeAmbients.isEmpty) {
      return 'No ambient';
    }

    return activeAmbients.map((sound) => sound.name(language)).join(' + ');
  }

  Future<void> togglePlay() async {
    isPlaying = !isPlaying;
    audioError = null;
    notifyListeners();

    if (isPlaying) {
      await _playActiveAmbients();
      await _audioService.playMusic();
    } else {
      await _audioService.pauseMusic();
      await _audioService.pauseAllAmbients();
    }
  }

  Future<void> _playActiveAmbients() async {
    try {
      for (final sound in activeAmbients) {
        await _audioService.loadAmbient(
          id: sound.id,
          assetPath: sound.assetPath,
          volume: ambientVolumeOf(sound.id),
        );
        await _audioService.playAmbient(sound.id);
      }
    } catch (_) {
      isPlaying = false;
      audioError = 'Không tìm thấy file ambient. Kiểm tra assets/audio/ambient.';
      notifyListeners();
    }
  }

  Future<void> toggleAmbient(String id) async {
    final sound = ambientSounds.firstWhere((item) => item.id == id);

    if (activeAmbientIds.contains(id)) {
      activeAmbientIds.remove(id);
      await _audioService.pauseAmbient(id);
    } else {
      activeAmbientIds.add(id);

      if (isPlaying) {
        try {
          await _audioService.loadAmbient(
            id: sound.id,
            assetPath: sound.assetPath,
            volume: ambientVolumeOf(sound.id),
          );
          await _audioService.playAmbient(sound.id);
        } catch (_) {
          activeAmbientIds.remove(id);
          audioError = 'Không tìm thấy file ${sound.assetPath}.';
        }
      }
    }

    notifyListeners();
  }

  Future<void> changeAmbientVolume(String id, double value) async {
    ambientVolumes[id] = value;

    if (activeAmbientIds.contains(id)) {
      await _audioService.setAmbientVolume(id, value);
    }

    notifyListeners();
  }

  Future<void> changeMusicVolume(double value) async {
    musicVolume = value;
    await _audioService.setMusicVolume(value);
    notifyListeners();
  }

  Future<void> toggleMusicLoop() async {
    isMusicLoopEnabled = !isMusicLoopEnabled;
    await _audioService.setMusicLoop(isMusicLoopEnabled);
    notifyListeners();
  }

  Future<void> applyPreset(int index) async {
    selectedPresetIndex = index;
    musicVolume = selectedPreset.musicVolume;
    defaultAmbientVolume = selectedPreset.ambientVolume;

    final oldActiveIds = activeAmbientIds.toList();

    for (final id in oldActiveIds) {
      await _audioService.pauseAmbient(id);
    }

    activeAmbientIds.clear();

    for (final id in selectedPreset.defaultAmbientIds) {
      activeAmbientIds.add(id);
      ambientVolumes[id] = defaultAmbientVolume;
    }

    if (isPlaying) {
      await _playActiveAmbients();
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}