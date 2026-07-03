import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../data/demo_data.dart';
import '../models/ambient_layer.dart';
import '../models/song.dart';
import '../services/user_data_service.dart';

class VibeController extends ChangeNotifier {
  final AudioPlayer musicPlayer = AudioPlayer();
  final Map<String, AudioPlayer> ambientPlayers = {};
  final List<StreamSubscription<dynamic>> subscriptions = [];

  final List<Song> songs = demoSongs;

  final List<AmbientLayer> ambientLayers = defaultAmbientLayers.map((layer) {
    return AmbientLayer(
      id: layer.id,
      name: layer.name,
      assetPath: layer.assetPath,
      icon: layer.icon,
      group: layer.group,
      volume: layer.volume,
      active: layer.active,
    );
  }).toList();

  final List<Song> likedSongs = [];
  final List<Song> recentlyPlayed = [];

  final List<String> savedVibes = [
    'Mưa nhẹ + Sóng biển êm',
    'Lofi Study',
    'Chill Night',
  ];

  Song? currentSong;
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  double musicVolume = 0.70;
  final Map<String, List<Song>> playlists = {'Daily Mix': demoSongs};

  String userName = 'Nguyễn Lương Nghĩa';
  String email = 'umter@st.vibe.app';
  String studentId = '2302700033';
  UserDataService? userDataService;

  Future<void> init() async {
    subscriptions.add(
      musicPlayer.playerStateStream.listen((state) {
        isPlaying = state.playing;
        notifyListeners();
      }),
    );

    subscriptions.add(
      musicPlayer.positionStream.listen((value) {
        position = value;
        notifyListeners();
      }),
    );

    subscriptions.add(
      musicPlayer.durationStream.listen((value) {
        duration = value ?? Duration.zero;
        notifyListeners();
      }),
    );

    await musicPlayer.setVolume(musicVolume);
  }

  void setProfile(String name, String mail, String id) {
    userName = name;
    email = mail;
    studentId = id;
    notifyListeners();
  }

  Future<void> attachUserDataService(UserDataService service) async {
    userDataService = service;
    await loadUserLibrary();
  }

  Future<void> loadUserLibrary() async {
    final service = userDataService;

    if (service == null) {
      return;
    }

    final data = await service.loadLibrary(email);
    likedSongs
      ..clear()
      ..addAll(_songsByIds(data.likedSongIds));
    recentlyPlayed
      ..clear()
      ..addAll(_songsByIds(data.recentlyPlayedSongIds));

    if (data.savedVibes.isNotEmpty) {
      savedVibes
        ..clear()
        ..addAll(data.savedVibes);
    }

    playlists
      ..clear()
      ..addAll(_playlistsByIds(data.playlists));

    if (playlists.isEmpty) {
      playlists['Daily Mix'] = songs;
    }

    notifyListeners();
  }

  Future<void> saveUserLibrary() async {
    final service = userDataService;

    if (service == null) {
      return;
    }

    await service.saveLibrary(
      email,
      UserLibraryData(
        likedSongIds: likedSongs.map((song) => song.id).toList(),
        recentlyPlayedSongIds: recentlyPlayed.map((song) => song.id).toList(),
        savedVibes: List<String>.from(savedVibes),
        playlists: playlists.map((name, playlistSongs) {
          return MapEntry(name, playlistSongs.map((song) => song.id).toList());
        }),
      ),
    );
  }

  Future<void> playSong(Song song) async {
    currentSong = song;
    position = Duration.zero;

    recentlyPlayed.removeWhere((item) => item.id == song.id);
    recentlyPlayed.insert(0, song);

    if (recentlyPlayed.length > 8) {
      recentlyPlayed.removeLast();
    }

    await saveUserLibrary();
    notifyListeners();

    try {
      await musicPlayer.stop();
      await musicPlayer.setAsset(song.assetPath);
      await musicPlayer.setVolume(musicVolume);
      await musicPlayer.play();
    } catch (_) {
      isPlaying = true;
      duration = song.duration;
      notifyListeners();
    }
  }

  Future<void> togglePlay() async {
    if (currentSong == null) {
      await playSong(songs.first);
      return;
    }

    if (musicPlayer.playing) {
      await musicPlayer.pause();
      isPlaying = false;
    } else {
      try {
        await musicPlayer.play();
        isPlaying = true;
      } catch (_) {
        isPlaying = true;
      }
    }

    notifyListeners();
  }

  Future<void> playNext() async {
    final current = currentSong;

    if (current == null) {
      await playSong(songs.first);
      return;
    }

    final index = songs.indexWhere((song) => song.id == current.id);
    await playSong(songs[(index + 1) % songs.length]);
  }

  Future<void> playPrevious() async {
    final current = currentSong;

    if (current == null) {
      await playSong(songs.first);
      return;
    }

    final index = songs.indexWhere((song) => song.id == current.id);
    await playSong(songs[(index - 1 + songs.length) % songs.length]);
  }

  Future<void> seek(double milliseconds) async {
    try {
      await musicPlayer.seek(
        Duration(milliseconds: milliseconds.round()),
      );
    } catch (_) {}
  }

  Future<void> setMusicVolume(double value) async {
    musicVolume = value;

    try {
      await musicPlayer.setVolume(value);
    } catch (_) {}

    notifyListeners();
  }

  bool isLiked(Song song) {
    return likedSongs.any((item) => item.id == song.id);
  }

  Future<void> toggleLiked(Song song) async {
    if (isLiked(song)) {
      likedSongs.removeWhere((item) => item.id == song.id);
    } else {
      likedSongs.insert(0, song);
    }

    await saveUserLibrary();
    notifyListeners();
  }

  Future<void> saveVibePreset(String name) async {
    final value = name.trim();

    if (value.isEmpty || savedVibes.contains(value)) {
      return;
    }

    savedVibes.insert(0, value);
    await saveUserLibrary();
    notifyListeners();
  }

  Future<void> removeVibePreset(String name) async {
    savedVibes.remove(name);
    await saveUserLibrary();
    notifyListeners();
  }

  List<Song> playlistSongs(String name) {
    return playlists[name] ?? const [];
  }

  Future<void> createPlaylist(String name) async {
    final value = name.trim();

    if (value.isEmpty || playlists.containsKey(value)) {
      return;
    }

    playlists[value] = [];
    await saveUserLibrary();
    notifyListeners();
  }

  Future<void> deletePlaylist(String name) async {
    if (name == 'Daily Mix') {
      return;
    }

    playlists.remove(name);
    await saveUserLibrary();
    notifyListeners();
  }

  Future<void> addSongToPlaylist(String playlistName, Song song) async {
    final playlist = playlists.putIfAbsent(playlistName, () => []);

    if (playlist.any((item) => item.id == song.id)) {
      return;
    }

    playlist.add(song);
    await saveUserLibrary();
    notifyListeners();
  }

  Future<void> removeSongFromPlaylist(String playlistName, Song song) async {
    final playlist = playlists[playlistName];

    if (playlist == null) {
      return;
    }

    playlist.removeWhere((item) => item.id == song.id);
    await saveUserLibrary();
    notifyListeners();
  }

  Future<void> toggleAmbient(AmbientLayer layer) async {
    final index = ambientLayers.indexWhere((item) => item.id == layer.id);

    if (index < 0) {
      return;
    }

    final current = ambientLayers[index];
    current.active = !current.active;

    notifyListeners();

    final player = ambientPlayers.putIfAbsent(
      current.id,
      () => AudioPlayer(),
    );

    if (current.active) {
      try {
        await player.stop();
        await player.setLoopMode(LoopMode.one);
        await player.setAsset(current.assetPath);
        await player.setVolume(current.volume);
        await player.play();
      } catch (_) {}
    } else {
      try {
        await player.pause();
      } catch (_) {}
    }

    notifyListeners();
  }

  Future<void> setAmbientVolume(AmbientLayer layer, double value) async {
    final index = ambientLayers.indexWhere((item) => item.id == layer.id);

    if (index < 0) {
      return;
    }

    ambientLayers[index].volume = value;

    final player = ambientPlayers[layer.id];

    if (player != null) {
      try {
        await player.setVolume(value);
      } catch (_) {}
    }

    notifyListeners();
  }

  Future<void> pauseAllAmbient() async {
    for (final layer in ambientLayers) {
      layer.active = false;
    }

    for (final player in ambientPlayers.values) {
      try {
        await player.pause();
      } catch (_) {}
    }

    notifyListeners();
  }

  Future<void> clearAmbient() async {
    for (final layer in ambientLayers) {
      layer.active = false;
      layer.volume = 0.45;
    }

    for (final player in ambientPlayers.values) {
      try {
        await player.stop();
      } catch (_) {}
    }

    notifyListeners();
  }

  Future<void> stopAll() async {
    try {
      await musicPlayer.stop();
    } catch (_) {}

    for (final player in ambientPlayers.values) {
      try {
        await player.stop();
      } catch (_) {}
    }

    isPlaying = false;
    notifyListeners();
  }

  int get activeAmbientCount {
    return ambientLayers.where((layer) => layer.active).length;
  }

  String get activeLayerText {
    final active = ambientLayers.where((layer) => layer.active).map((layer) {
      return layer.name;
    }).toList();

    if (active.isEmpty) {
      return 'No ambient';
    }

    if (active.length <= 2) {
      return active.join(' + ');
    }

    return '${active.take(2).join(' + ')} + ${active.length - 2} lớp';
  }

  List<Song> _songsByIds(List<String> ids) {
    final results = <Song>[];

    for (final id in ids) {
      final index = songs.indexWhere((song) => song.id == id);

      if (index >= 0) {
        results.add(songs[index]);
      }
    }

    return results;
  }

  Map<String, List<Song>> _playlistsByIds(Map<String, List<String>> source) {
    return source.map((name, ids) {
      return MapEntry(name, _songsByIds(ids));
    });
  }

  @override
  void dispose() {
    for (final sub in subscriptions) {
      sub.cancel();
    }

    musicPlayer.dispose();

    for (final player in ambientPlayers.values) {
      player.dispose();
    }

    super.dispose();
  }
}
