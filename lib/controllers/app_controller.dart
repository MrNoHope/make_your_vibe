library app_controller;

import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';
import '../services/services.dart';

part 'features/search_actions.dart';
part 'features/player_actions.dart';
part 'features/library_actions.dart';
part 'features/vibe_actions.dart';
part 'features/community_actions.dart';
part 'features/profile_actions.dart';

enum QueueRepeatMode { off, one, all }

enum PlayerLoadPhase { idle, resolving, loading, ready, error }

class AppController extends ChangeNotifier {
  AppController({required this.audio});

  final LocalStore store = LocalStore();
  late final LocalAuthService auth;
  final MusicGateway music = MusicGateway();
  final AudioGateway audio;
  final AmbientGateway ambient = AmbientGateway();
  final LocalMediaService media = LocalMediaService();

  bool initialized = false;
  bool preparing = false;
  bool searching = false;
  bool suggesting = false;
  bool english = false;
  bool dark = true;
  bool playing = false;
  bool _handlingCompletion = false;
  bool shuffleEnabled = false;
  QueueRepeatMode repeatMode = QueueRepeatMode.off;
  PlayerLoadPhase playerPhase = PlayerLoadPhase.idle;
  String error = '';
  String playerError = '';
  String loadingSongId = '';
  UserProfile? user;

  List<Song> searchResults = [];
  List<String> searchSuggestions = [];
  List<String> searchHistory = [];
  List<Song> recent = [];
  List<Song> uploads = [];
  List<Song> librarySongs = [];
  Set<String> liked = {};
  List<PlaylistModel> playlists = [];
  List<VibePreset> vibes = [];
  Set<String> likedPosts = {};
  Set<String> savedPosts = {};

  Song? currentSong;
  Song? pendingSong;
  Song? get playerSong => pendingSong ?? currentSong;
  List<Song> queue = [];
  int queueIndex = -1;
  int _request = 0;
  int _suggestRequest = 0;
  int _searchRequest = 0;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  Duration bufferedPosition = Duration.zero;
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> durationNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> bufferedPositionNotifier =
      ValueNotifier(Duration.zero);

  late StreamSubscription<PlayerState> _stateSubscription;
  late StreamSubscription<Duration> _positionSubscription;
  late StreamSubscription<Duration?> _durationSubscription;
  late StreamSubscription<ProcessingState> _processingSubscription;
  late StreamSubscription<Duration> _bufferedPositionSubscription;

  final List<Song> seedSongs = const [
    Song(
      id: '60ItHLz5WEA',
      title: 'Faded',
      artist: 'Alan Walker',
      artworkUrl: 'https://i.ytimg.com/vi/60ItHLz5WEA/hqdefault.jpg',
    ),
    Song(
      id: 'hT_nvWreIhg',
      title: 'Counting Stars',
      artist: 'OneRepublic',
      artworkUrl: 'https://i.ytimg.com/vi/hT_nvWreIhg/hqdefault.jpg',
    ),
    Song(
      id: 'RgKAFK5djSk',
      title: 'See You Again',
      artist: 'Wiz Khalifa ft. Charlie Puth',
      artworkUrl: 'https://i.ytimg.com/vi/RgKAFK5djSk/hqdefault.jpg',
    ),
  ];


  String tr(String vi, String en) => english ? en : vi;

  Color get accentColor => Color(user?.accent ?? 0xFF74E26B);

  Future<void> init() async {
    await store.init();
    auth = LocalAuthService(store);
    await audio.init();
    audio.onNext = () => AppPlayerActions(this).next();
    audio.onPrevious = () => AppPlayerActions(this).previous();
    audio.onTaskRemovedCallback = () async {
      await ambient.stopAll();
    };
    ambient.onActivityChanged = (active) {
      unawaited(audio.setAmbientActive(active));
    };
    audio.onError = (message) {
      if (playerSong == null) return;
      playerPhase = PlayerLoadPhase.error;
      playerError = tr(
        'Không thể phát bài này. Bạn có thể thử lại hoặc chọn bài khác.',
        'This track cannot be played. Retry or choose another track.',
      );
      preparing = false;
      loadingSongId = '';
      notifyListeners();
    };
    user = auth.restore();
    dark = store.getBool('dark', true);
    english = store.getBool('english', false);
    if (user != null) await _loadUserData();

    _stateSubscription = audio.playerStateStream.listen((state) {
      playing = state.playing;
      notifyListeners();
    });
    _positionSubscription = audio.positionStream.listen((value) {
      position = value;
      positionNotifier.value = value;
    });
    _durationSubscription = audio.durationStream.listen((value) {
      duration = value ?? Duration.zero;
      durationNotifier.value = duration;
    });
    _bufferedPositionSubscription = audio.bufferedPositionStream.listen((value) {
      bufferedPosition = value;
      bufferedPositionNotifier.value = value;
    });
    _processingSubscription = audio.processingStateStream.listen(
      (state) {
        if (state == ProcessingState.loading ||
            state == ProcessingState.buffering) {
          if (playerSong != null &&
              playerPhase != PlayerLoadPhase.resolving) {
            playerPhase = PlayerLoadPhase.loading;
          }
        } else if (state == ProcessingState.ready && currentSong != null) {
          playerPhase = PlayerLoadPhase.ready;
          playerError = '';
        } else if (state == ProcessingState.completed) {
          unawaited(AppPlayerActions(this)._autoAdvance());
        }
        notifyListeners();
      },
    );

    unawaited(music.prefetchMany(seedSongs, maxCount: seedSongs.length));
    initialized = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await _guard(() async {
      user = await auth.login(email, password);
      await _loadUserData();
    });
  }

  Future<void> register(String name, String email, String password) async {
    await _guard(() async {
      user = await auth.register(name, email, password);
      await _loadUserData();
    });
  }

  Future<void> social(String provider) async {
    await _guard(() async {
      user = await auth.social(provider);
      await _loadUserData();
    });
  }

  Future<void> logout() async {
    _request++;
    _searchRequest++;
    _suggestRequest++;
    await auth.logout();
    await audio.reset();
    await ambient.stopAll();
    user = null;
    currentSong = null;
    pendingSong = null;
    playerPhase = PlayerLoadPhase.idle;
    playerError = '';
    queue = [];
    queueIndex = -1;
    position = Duration.zero;
    duration = Duration.zero;
    bufferedPosition = Duration.zero;
    positionNotifier.value = Duration.zero;
    durationNotifier.value = Duration.zero;
    bufferedPositionNotifier.value = Duration.zero;
    playing = false;
    preparing = false;
    searching = false;
    suggesting = false;
    searchSuggestions = [];
    error = '';
    loadingSongId = '';
    _resetUserData();
    notifyListeners();
  }

  Future<void> _guard(Future<void> Function() task) async {
    error = '';
    try {
      await task();
    } catch (exception) {
      error = exception.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  String _key(String name) => '${user!.id}_$name';

  Future<void> _loadUserData() async {
    if (user == null) return;
    liked = store
        .getMaps(_key('liked_songs'))
        .map((item) => '${item['id']}')
        .toSet();
    librarySongs = store
        .getMaps(_key('library_songs'))
        .map(Song.fromMap)
        .toList();
    playlists = store
        .getMaps(_key('playlists'))
        .map(PlaylistModel.fromMap)
        .toList();
    uploads = store.getMaps(_key('uploads')).map(Song.fromMap).toList();
    vibes = store.getMaps(_key('vibes')).map(VibePreset.fromMap).toList();
    likedPosts = store
        .getMaps(_key('liked_posts'))
        .map((item) => '${item['id']}')
        .toSet();
    savedPosts = store
        .getMaps(_key('saved_posts'))
        .map((item) => '${item['id']}')
        .toSet();
    recent = store.getMaps(_key('recent')).map(Song.fromMap).toList();
    searchHistory = store.getStrings(_key('search_history'));

    if (vibes.isEmpty) {
      vibes = _defaultVibes();
      await _saveVibes();
    }

    unawaited(
      music.prefetchMany(
        [...recent, ...librarySongs],
        maxCount: 8,
      ),
    );
  }

  void _resetUserData() {
    searchResults = [];
    searchSuggestions = [];
    searchHistory = [];
    recent = [];
    uploads = [];
    librarySongs = [];
    liked = {};
    playlists = [];
    vibes = [];
    likedPosts = {};
    savedPosts = {};
  }

  List<VibePreset> _defaultVibes() => const [
        VibePreset(
          id: 'sample_study',
          name: 'Study Rain',
          description: 'Lofi và mưa nhẹ',
          songId: '60ItHLz5WEA',
          levels: {'soft_rain': 0.55, 'soft_brown_noise': 0.18},
          masterVolume: 0.8,
          isPublic: true,
          likes: 128,
        ),
        VibePreset(
          id: 'sample_sleep',
          name: 'Ocean Sleep',
          description: 'Biển êm và brown noise',
          levels: {
            'ocean_waves_smooth': 0.65,
            'smooth_brown_noise': 0.28,
          },
          masterVolume: 0.72,
          isPublic: true,
          likes: 94,
        ),
      ];


  List<Song> get allSongs {
    final songs = <String, Song>{};
    for (final song in [
      ...seedSongs,
      ...librarySongs,
      ...searchResults,
      ...recent,
      ...uploads,
      ...queue,
    ]) {
      songs[song.id] = song;
    }
    return songs.values.toList();
  }

  List<Song> get likedSongs =>
      allSongs.where((song) => liked.contains(song.id)).toList();

  Future<void> _rememberSong(Song song) async {
    if (song.source == SongSource.local) return;
    final clean = song.copyWith(streamUrl: '');
    final index = librarySongs.indexWhere((item) => item.id == clean.id);
    if (index >= 0) {
      librarySongs[index] = clean;
    } else {
      librarySongs.add(clean);
    }
    await store.setMaps(
      _key('library_songs'),
      librarySongs.map((item) => item.toMap()),
    );
  }

  Future<void> _addRecent(Song song) async {
    final clean = song.copyWith(streamUrl: '');
    recent.removeWhere((item) => item.id == clean.id);
    recent.insert(0, clean);
    if (recent.length > 30) recent = recent.take(30).toList();
    await _rememberSong(clean);
    await store.setMaps(
      _key('recent'),
      recent.map((item) => item.toMap()),
    );
  }

  Future<void> _savePlaylists() => store.setMaps(
        _key('playlists'),
        playlists.map((item) => item.toMap()),
      );

  Future<void> _saveUploads() => store.setMaps(
        _key('uploads'),
        uploads.map((item) => item.toMap()),
      );

  Future<void> _saveVibes() => store.setMaps(
        _key('vibes'),
        vibes.map((item) => item.toMap()),
      );

  @override
  void dispose() {
    unawaited(_stateSubscription.cancel());
    unawaited(_positionSubscription.cancel());
    unawaited(_durationSubscription.cancel());
    unawaited(_processingSubscription.cancel());
    unawaited(_bufferedPositionSubscription.cancel());
    unawaited(audio.disposePlayer());
    unawaited(ambient.dispose());
    music.dispose();
    positionNotifier.dispose();
    durationNotifier.dispose();
    bufferedPositionNotifier.dispose();
    super.dispose();
  }
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
