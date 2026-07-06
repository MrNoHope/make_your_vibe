import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';
import '../services/audio_gateway.dart';
import '../services/music_gateway.dart';

class VibeController extends ChangeNotifier {
  final MusicGateway music = musicGateway;
  final AudioGateway audio = audioGateway;

  Song? currentSong;
  List<Song> homeSongs = [];
  List<Song> searchResults = [];
  List<Song> activeQueue = [];

  bool isPlaying = false;
  bool loadingHome = false;
  bool searching = false;
  bool resolving = false;
  int currentIndex = 0;
  String errorMessage = '';

  StreamSubscription<PlayerState>? _playerSub;

  VibeController() {
    _playerSub = audio.playerStateStream.listen((state) {
      isPlaying = state.playing;
      notifyListeners();
    });
  }

  Future<void> loadHomeSongs() async {
    if (loadingHome || homeSongs.isNotEmpty) {
      return;
    }

    loadingHome = true;
    errorMessage = '';
    notifyListeners();

    try {
      homeSongs = await music.getHomeTracks();
      activeQueue = homeSongs;
    } catch (error) {
      errorMessage = 'Không tải được nhạc: $error';
    }

    loadingHome = false;
    notifyListeners();
  }

  Future<void> searchSongs(String keyword) async {
    final query = keyword.trim();

    if (query.isEmpty) {
      searchResults = [];
      notifyListeners();
      return;
    }

    searching = true;
    errorMessage = '';
    notifyListeners();

    try {
      searchResults = await music.searchTracks(query);
      activeQueue = searchResults;
    } catch (error) {
      errorMessage = 'Search lỗi: $error';
    }

    searching = false;
    notifyListeners();
  }

  Future<void> playSong(Song song, {List<Song>? queue}) async {
    final chosenQueue = queue ?? activeQueue;

    if (chosenQueue.isNotEmpty) {
      activeQueue = chosenQueue;
      final foundIndex = chosenQueue.indexWhere((item) => item.id == song.id);
      currentIndex = foundIndex < 0 ? 0 : foundIndex;
    }

    resolving = true;
    errorMessage = '';
    currentSong = song;
    notifyListeners();

    try {
      final resolved = await music.resolveStream(song);
      currentSong = resolved;

      if (activeQueue.isNotEmpty) {
        activeQueue = activeQueue.map((item) {
          return item.id == resolved.id ? resolved : item;
        }).toList();
      }

      await audio.play(resolved);
    } catch (error) {
      errorMessage = 'Không phát được bài này: $error';
    }

    resolving = false;
    notifyListeners();
  }

  Future<void> togglePlay() async {
    if (currentSong == null) {
      if (activeQueue.isNotEmpty) {
        await playSong(activeQueue.first, queue: activeQueue);
      }
      return;
    }

    if (audio.isPlaying) {
      await audio.pause();
    } else {
      await audio.resume();
    }

    notifyListeners();
  }

  Future<void> nextSong() async {
    if (activeQueue.isEmpty) {
      return;
    }

    final nextIndex = currentIndex + 1 >= activeQueue.length ? 0 : currentIndex + 1;
    currentIndex = nextIndex;
    await playSong(activeQueue[nextIndex], queue: activeQueue);
  }

  Future<void> previousSong() async {
    if (activeQueue.isEmpty) {
      return;
    }

    if (audio.position.inSeconds > 3) {
      await audio.seek(Duration.zero);
      return;
    }

    final previousIndex = currentIndex - 1 < 0 ? activeQueue.length - 1 : currentIndex - 1;
    currentIndex = previousIndex;
    await playSong(activeQueue[previousIndex], queue: activeQueue);
  }

  Future<void> seek(Duration position) async {
    await audio.seek(position);
  }

  Future<void> reset() async {
    await audio.stop();
    currentSong = null;
    isPlaying = false;
    currentIndex = 0;
    notifyListeners();
  }

  String formatDuration(Duration duration) {
    final seconds = duration.inSeconds;
    final minutes = seconds ~/ 60;
    final remain = seconds % 60;
    return '$minutes:${remain.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    audio.dispose();
    music.close();
    super.dispose();
  }
}
