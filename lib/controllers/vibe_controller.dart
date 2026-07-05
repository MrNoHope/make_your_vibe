import 'package:flutter/foundation.dart';

import '../models/song.dart';

class VibeController extends ChangeNotifier {
  Song? currentSong;
  bool isPlaying = false;
  int currentIndex = 0;

  void selectSong(Song song) {
    currentSong = song;
    isPlaying = false;
    notifyListeners();
  }

  void togglePlay() {
    isPlaying = !isPlaying;
    notifyListeners();
  }

  void reset() {
    currentSong = null;
    isPlaying = false;
    currentIndex = 0;
    notifyListeners();
  }
}