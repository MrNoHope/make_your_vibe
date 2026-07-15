part of app_controller;

extension AppPlayerActions on AppController {
  Future<void> playSong(Song song, {List<Song>? fromQueue}) async {
    if (currentSong?.id == song.id &&
        pendingSong == null &&
        audio.loadedSong?.id == song.id) {
      await audio.toggle();
      return;
    }

    final request = ++_request;
    pendingSong = song;
    preparing = true;
    playerPhase = PlayerLoadPhase.resolving;
    playerError = '';
    loadingSongId = song.id;
    error = '';

    if (fromQueue != null && fromQueue.isNotEmpty) {
      queue = List<Song>.of(fromQueue);
      queueIndex = queue.indexWhere((item) => item.id == song.id);
    } else {
      queue = [song];
      queueIndex = 0;
    }

    notifyListeners();

    try {
      final candidates = await music.resolveCandidates(song);
      if (request != _request) return;

      Song? ready;
      for (final candidate in candidates.take(3)) {
        if (request != _request) return;
        try {
          playerPhase = PlayerLoadPhase.loading;
          notifyListeners();
          final loaded = await audio.loadAndPlay(
            candidate,
            requestId: request,
          );
          if (!loaded || request != _request) return;
          ready = candidate;
          break;
        } catch (_) {
          if (request != _request) return;
        }
      }

      if (ready == null) {
        music.invalidate(song.id);
        throw Exception('Không có luồng nào phát được.');
      }
      if (request != _request) return;

      currentSong = ready;
      pendingSong = null;
      playerPhase = PlayerLoadPhase.ready;
      playerError = '';
      preparing = false;
      loadingSongId = '';
      position = Duration.zero;
      positionNotifier.value = Duration.zero;
      await _addRecent(ready);
      notifyListeners();

      final nextSong = queueIndex >= 0 && queueIndex + 1 < queue.length
          ? queue[queueIndex + 1]
          : null;
      if (nextSong != null) {
        unawaited(_preloadNext(nextSong, request));
      }
    } catch (_) {
      if (request != _request) return;
      preparing = false;
      loadingSongId = '';
      playerPhase = PlayerLoadPhase.error;
      playerError = tr(
        'Không phát được bài này. Nhấn thử lại hoặc chọn bài khác.',
        'This track could not be played. Retry or choose another track.',
      );
      notifyListeners();
    }
  }

  Future<void> _preloadNext(Song song, int request) async {
    try {
      final candidates = await music.resolveCandidates(song);
      if (request != _request || candidates.isEmpty) return;
      await audio.preload(candidates.first);
    } catch (_) {
      // The next-track preload is optional and never blocks playback.
    }
  }

  Future<void> retryPlayer() async {
    final song = pendingSong ?? currentSong;
    if (song == null) return;
    music.invalidate(song.id);
    await playSong(song, fromQueue: queue.isEmpty ? [song] : queue);
  }

  Future<void> dismissPlayerError() async {
    pendingSong = null;
    playerError = '';
    playerPhase = currentSong == null
        ? PlayerLoadPhase.idle
        : PlayerLoadPhase.ready;
    notifyListeners();
  }

  Future<void> togglePlay() async {
    if (playerPhase == PlayerLoadPhase.error) {
      await retryPlayer();
      return;
    }
    if (pendingSong != null) return;
    if (currentSong == null) {
      await playSong(seedSongs.first, fromQueue: seedSongs);
      return;
    }
    await audio.toggle();
  }

  Future<void> next() async {
    if (queue.isEmpty) return;
    if (shuffleEnabled && queue.length > 1) {
      final current = queueIndex;
      final seed = DateTime.now().microsecondsSinceEpoch;
      var target = seed % queue.length;
      if (target == current) target = (target + 1) % queue.length;
      queueIndex = target;
    } else {
      queueIndex = (queueIndex + 1) % queue.length;
    }
    await playSong(queue[queueIndex], fromQueue: queue);
  }

  Future<void> seekBy(Duration offset) async {
    if (currentSong == null || pendingSong != null) return;
    final target = position + offset;
    final max = duration > Duration.zero ? duration : currentSong?.duration;
    var nextPosition = target < Duration.zero ? Duration.zero : target;
    if (max != null && max > Duration.zero && nextPosition > max) {
      nextPosition = max;
    }
    await audio.seek(nextPosition);
  }

  void toggleShuffle() {
    shuffleEnabled = !shuffleEnabled;
    notifyListeners();
  }

  void cycleRepeatMode() {
    switch (repeatMode) {
      case QueueRepeatMode.off:
        repeatMode = QueueRepeatMode.one;
        break;
      case QueueRepeatMode.one:
        repeatMode = QueueRepeatMode.all;
        break;
      case QueueRepeatMode.all:
        repeatMode = QueueRepeatMode.off;
        break;
    }
    notifyListeners();
  }

  Future<void> previous() async {
    if (pendingSong == null && position > const Duration(seconds: 5)) {
      await audio.seek(Duration.zero);
      return;
    }
    if (queue.isEmpty) return;
    queueIndex = (queueIndex - 1 + queue.length) % queue.length;
    await playSong(queue[queueIndex], fromQueue: queue);
  }

  Future<void> _autoAdvance() async {
    if (_handlingCompletion) return;
    _handlingCompletion = true;
    try {
      if (repeatMode == QueueRepeatMode.one) {
        await audio.seek(Duration.zero);
        await audio.play();
        return;
      }
      if (queueIndex >= 0 && queueIndex + 1 < queue.length) {
        await next();
        return;
      }
      if (repeatMode == QueueRepeatMode.all && queue.isNotEmpty) {
        queueIndex = -1;
        await next();
        return;
      }
      await audio.pause();
      await audio.seek(Duration.zero);
    } finally {
      _handlingCompletion = false;
    }
  }

  Future<void> seek(Duration value) async {
    if (currentSong == null || pendingSong != null) return;
    await audio.seek(value);
  }
}
