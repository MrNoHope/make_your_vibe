part of app_controller;

extension AppVibeActions on AppController {
  Future<void> saveVibe(
    String name,
    String description,
    bool isPublic, {
    String coverPath = '',
  }) async {
    if (name.trim().isEmpty) return;
    vibes.insert(
      0,
      VibePreset(
        id: 'v_${DateTime.now().microsecondsSinceEpoch}',
        name: name.trim(),
        description: description.trim(),
        coverPath: coverPath,
        songId: currentSong?.id ?? '',
        levels: Map<String, double>.of(ambient.levels),
        masterVolume: ambient.masterVolume,
        isPublic: isPublic,
      ),
    );
    if (currentSong != null) await _rememberSong(currentSong!);
    await _saveVibes();
    notifyListeners();
  }

  Future<void> updateVibe(
    VibePreset vibe, {
    required String name,
    required String description,
    required bool isPublic,
    String coverPath = '',
  }) async {
    final index = vibes.indexWhere((item) => item.id == vibe.id);
    if (index < 0 || name.trim().isEmpty) return;
    final nextCover = coverPath.isEmpty ? vibe.coverPath : coverPath;
    vibes[index] = vibe.copyWith(
      name: name.trim(),
      description: description.trim(),
      coverPath: nextCover,
      isPublic: isPublic,
    );
    if (coverPath.isNotEmpty && coverPath != vibe.coverPath) {
      await media.delete(vibe.coverPath);
    }
    await _saveVibes();
    notifyListeners();
  }

  Future<void> applyVibe(VibePreset vibe) async {
    await ambient.apply(
      vibe.levels,
      master: vibe.masterVolume,
    );
    final song = allSongs
        .where((item) => item.id == vibe.songId)
        .firstOrNull;
    if (song != null) await playSong(song, fromQueue: allSongs);
    notifyListeners();
  }

  Future<void> deleteVibe(VibePreset vibe) async {
    if (vibe.id.startsWith('sample_')) return;
    vibes.removeWhere((item) => item.id == vibe.id);
    await media.delete(vibe.coverPath);
    await _saveVibes();
    notifyListeners();
  }

  Future<void> setAmbient(String id, double value) async {
    await ambient.setLevel(id, value);
    notifyListeners();
  }

  Future<void> setAmbientMaster(double value) async {
    await ambient.setMaster(value);
    notifyListeners();
  }

  Future<void> stopAmbient() async {
    await ambient.stopAll();
    notifyListeners();
  }
}
