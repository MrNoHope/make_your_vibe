import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart' as ja;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

const _youtubeApiKey = String.fromEnvironment('YOUTUBE_API_KEY');
const _backgroundColor = Color(0xFF0C1116);
const _surfaceColor = Color(0xFF151B21);
const _surfaceColorAlt = Color(0xFF1C242C);
const _accentColor = Color(0xFF14B8A6);
const _highlightColor = Color(0xFF155E75);

void main() {
  runApp(const MucsicApp());
}

class MucsicApp extends StatelessWidget {
  const MucsicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mucsic',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _accentColor,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: _backgroundColor,
        cardTheme: const CardThemeData(
          color: _surfaceColor,
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
      ),
      home: const MusicHomePage(),
    );
  }
}

class YouTubeTrack {
  const YouTubeTrack({
    required this.videoId,
    required this.title,
    required this.channel,
    required this.thumbnailUrl,
    required this.publishedAt,
  });

  final String videoId;
  final String title;
  final String channel;
  final String thumbnailUrl;
  final String publishedAt;

  factory YouTubeTrack.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as Map<String, dynamic>? ?? {};
    final snippet = json['snippet'] as Map<String, dynamic>? ?? {};
    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>? ?? {};
    final medium = thumbnails['medium'] as Map<String, dynamic>? ?? {};
    final fallback = thumbnails['default'] as Map<String, dynamic>? ?? {};

    return YouTubeTrack(
      videoId: id['videoId']?.toString() ?? '',
      title: _decodeHtml(snippet['title']?.toString() ?? 'Untitled'),
      channel: _decodeHtml(snippet['channelTitle']?.toString() ?? 'YouTube'),
      thumbnailUrl:
          medium['url']?.toString() ?? fallback['url']?.toString() ?? '',
      publishedAt: snippet['publishedAt']?.toString() ?? '',
    );
  }
}

class YouTubeMusicService {
  const YouTubeMusicService({required this.apiKey});

  final String apiKey;

  Future<List<YouTubeTrack>> searchTracks(String query) async {
    if (apiKey.isEmpty) {
      throw const YouTubeApiKeyMissingException();
    }

    final searchText = query.trim().isEmpty
        ? 'bray official music video'
        : query.trim();
    final uri = Uri.https('www.googleapis.com', '/youtube/v3/search', {
      'key': apiKey,
      'part': 'snippet',
      'type': 'video',
      'videoCategoryId': '10',
      'videoEmbeddable': 'true',
      'maxResults': '25',
      'order': 'relevance',
      'regionCode': 'VN',
      'relevanceLanguage': 'vi',
      'safeSearch': 'moderate',
      'q': '$searchText music official audio MV',
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
      final error = decoded?['error'] as Map<String, dynamic>?;
      throw Exception(
        error?['message'] ?? 'YouTube returned HTTP ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final items = decoded['items'] as List<dynamic>? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(YouTubeTrack.fromJson)
        .where((track) => track.videoId.isNotEmpty)
        .toList();
  }
}

class YouTubeApiKeyMissingException implements Exception {
  const YouTubeApiKeyMissingException();
}

enum LocalMediaType { audio, video }

class LocalMediaItem {
  const LocalMediaItem({
    required this.name,
    required this.path,
    required this.type,
    required this.ownerName,
  });

  final String name;
  final String path;
  final LocalMediaType type;
  final String ownerName;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'type': type.name,
      'ownerName': ownerName,
    };
  }

  factory LocalMediaItem.fromJson(Map<String, dynamic> json) {
    final typeName = json['type']?.toString() ?? LocalMediaType.audio.name;
    return LocalMediaItem(
      name: json['name']?.toString() ?? 'Untitled',
      path: json['path']?.toString() ?? '',
      type: LocalMediaType.values.firstWhere(
        (type) => type.name == typeName,
        orElse: () => LocalMediaType.audio,
      ),
      ownerName: json['ownerName']?.toString() ?? 'student',
    );
  }
}

class DemoUserProfile {
  const DemoUserProfile({
    required this.name,
    required this.email,
    required this.bio,
  });

  final String name;
  final String email;
  final String bio;

  Map<String, dynamic> toJson() {
    return {'name': name, 'email': email, 'bio': bio};
  }

  factory DemoUserProfile.fromJson(Map<String, dynamic> json) {
    return DemoUserProfile(
      name: json['name']?.toString() ?? 'student',
      email: json['email']?.toString() ?? 'student@mucsic.local',
      bio: json['bio']?.toString() ?? 'Music lover',
    );
  }
}

class DemoPlaylist {
  const DemoPlaylist({
    required this.name,
    required this.description,
    required this.itemIds,
  });

  final String name;
  final String description;
  final List<String> itemIds;

  Map<String, dynamic> toJson() {
    return {'name': name, 'description': description, 'itemIds': itemIds};
  }

  factory DemoPlaylist.fromJson(Map<String, dynamic> json) {
    final rawIds = json['itemIds'];
    return DemoPlaylist(
      name: json['name']?.toString() ?? 'My Playlist',
      description: json['description']?.toString() ?? 'Saved songs',
      itemIds: rawIds is List
          ? rawIds.map((id) => id.toString()).toList()
          : <String>[],
    );
  }
}

class LocalLibrarySnapshot {
  const LocalLibrarySnapshot({
    this.user,
    required this.items,
    required this.favoriteIds,
    required this.playlists,
  });

  final DemoUserProfile? user;
  final List<LocalMediaItem> items;
  final Set<String> favoriteIds;
  final List<DemoPlaylist> playlists;
}

class DemoLocalStorage {
  const DemoLocalStorage();

  Future<File> _storageFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File(
      '${directory.path}${Platform.pathSeparator}mucsic_demo_library.json',
    );
  }

  Future<LocalLibrarySnapshot> load() async {
    try {
      final file = await _storageFile();
      if (!await file.exists()) {
        return LocalLibrarySnapshot(
          items: const [],
          favoriteIds: const {},
          playlists: _defaultPlaylists(),
        );
      }
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        return LocalLibrarySnapshot(
          items: const [],
          favoriteIds: const {},
          playlists: _defaultPlaylists(),
        );
      }
      final rawItems = decoded['items'];
      final items = rawItems is List
          ? rawItems
                .whereType<Map<String, dynamic>>()
                .map(LocalMediaItem.fromJson)
                .where(
                  (item) =>
                      item.path.isNotEmpty && File(item.path).existsSync(),
                )
                .toList()
          : <LocalMediaItem>[];
      final rawFavorites = decoded['favoriteIds'];
      final favoriteIds = rawFavorites is List
          ? rawFavorites.map((id) => id.toString()).toSet()
          : <String>{};
      final rawPlaylists = decoded['playlists'];
      final playlists = rawPlaylists is List
          ? rawPlaylists
                .whereType<Map<String, dynamic>>()
                .map(DemoPlaylist.fromJson)
                .toList()
          : _defaultPlaylists();
      return LocalLibrarySnapshot(
        user: decoded['user'] is Map<String, dynamic>
            ? DemoUserProfile.fromJson(decoded['user'] as Map<String, dynamic>)
            : _legacyUser(decoded['userName']?.toString()),
        items: items,
        favoriteIds: favoriteIds,
        playlists: playlists.isEmpty ? _defaultPlaylists() : playlists,
      );
    } catch (_) {
      return LocalLibrarySnapshot(
        items: const [],
        favoriteIds: const {},
        playlists: _defaultPlaylists(),
      );
    }
  }

  Future<void> save({
    required DemoUserProfile? user,
    required List<LocalMediaItem> items,
    required Set<String> favoriteIds,
    required List<DemoPlaylist> playlists,
  }) async {
    final file = await _storageFile();
    final payload = {
      'user': user?.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'favoriteIds': favoriteIds.toList(),
      'playlists': playlists.map((playlist) => playlist.toJson()).toList(),
    };
    await file.writeAsString(jsonEncode(payload));
  }

  static List<DemoPlaylist> _defaultPlaylists() {
    return const [
      DemoPlaylist(
        name: 'Favorites Mix',
        description: 'Playlist demo for saved songs',
        itemIds: [],
      ),
      DemoPlaylist(
        name: 'Study Session',
        description: 'Music for coding and homework',
        itemIds: [],
      ),
    ];
  }

  static DemoUserProfile? _legacyUser(String? name) {
    if (name == null || name.trim().isEmpty) {
      return null;
    }
    return DemoUserProfile(
      name: name,
      email: '${name.toLowerCase().replaceAll(' ', '')}@mucsic.local',
      bio: 'Music lover',
    );
  }
}

class MusicHomePage extends StatefulWidget {
  const MusicHomePage({super.key});

  @override
  State<MusicHomePage> createState() => _MusicHomePageState();
}

class _MusicHomePageState extends State<MusicHomePage> {
  final _queryController = TextEditingController(text: 'bray');
  final _service = const YouTubeMusicService(apiKey: _youtubeApiKey);
  final _storage = const DemoLocalStorage();
  final _audioPlayer = ja.AudioPlayer();

  List<YouTubeTrack> _tracks = const [];
  final List<LocalMediaItem> _localItems = [];
  final List<String> _searchHistory = ['bray'];
  final Set<String> _favoriteIds = <String>{};
  List<DemoPlaylist> _playlists = DemoLocalStorage._defaultPlaylists();
  YouTubeTrack? _currentTrack;
  LocalMediaItem? _currentLocalItem;
  YoutubePlayerController? _playerController;
  VideoPlayerController? _videoController;
  StreamSubscription<YoutubePlayerValue>? _playerSubscription;
  StreamSubscription<ja.PlayerState>? _audioSubscription;
  bool _isLoading = false;
  bool _handledEndedState = false;
  bool _isLocalAudioPlaying = false;
  int _selectedTab = 0;
  int _librarySection = 0;
  String _activeQuery = 'bray';
  DemoUserProfile? _signedInUser;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadSavedLibrary();
    _audioSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) {
        return;
      }
      setState(() => _isLocalAudioPlaying = state.playing);
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _playerSubscription?.cancel();
    _audioSubscription?.cancel();
    _playerController?.close();
    _audioPlayer.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLibrary() async {
    final snapshot = await _storage.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _signedInUser = snapshot.user;
      _localItems
        ..clear()
        ..addAll(snapshot.items);
      _favoriteIds
        ..clear()
        ..addAll(snapshot.favoriteIds);
      _playlists = snapshot.playlists;
      if (snapshot.user != null || snapshot.items.isNotEmpty) {
        _message = 'Loaded saved demo library.';
      }
    });
  }

  Future<void> _saveLibrary() {
    return _storage.save(
      user: _signedInUser,
      items: _localItems,
      favoriteIds: _favoriteIds,
      playlists: _playlists,
    );
  }

  Future<void> _search({bool playFirst = false}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final query = _queryController.text.trim().isEmpty
        ? 'bray'
        : _queryController.text.trim();
    setState(() {
      _isLoading = true;
      _message = null;
      _activeQuery = query;
    });

    try {
      final tracks = await _service.searchTracks(query);
      if (!mounted) {
        return;
      }
      setState(() {
        _tracks = tracks;
        _message = tracks.isEmpty ? 'No YouTube music videos found.' : null;
      });
      if (playFirst && tracks.isNotEmpty) {
        _playTrack(tracks.first);
      }
    } on YouTubeApiKeyMissingException {
      if (!mounted) {
        return;
      }
      setState(() {
        _tracks = const [];
        _message =
            'Add a YouTube API key with --dart-define=YOUTUBE_API_KEY=...';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _tracks = const [];
        _message = 'Search failed: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openSearch() async {
    final query = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => _SearchPage(
          initialQuery: _queryController.text,
          history: _searchHistory,
          tracks: _tracks,
        ),
      ),
    );

    if (query == null || query.trim().isEmpty) {
      return;
    }

    _queryController.text = query.trim();
    _addSearchHistory(query.trim());
    await _search();
  }

  void _addSearchHistory(String query) {
    _searchHistory.removeWhere(
      (item) => item.toLowerCase() == query.toLowerCase(),
    );
    _searchHistory.insert(0, query);
    if (_searchHistory.length > 8) {
      _searchHistory.removeRange(8, _searchHistory.length);
    }
  }

  Future<void> _playTrack(YouTubeTrack track) async {
    await _stopLocalPlayback();
    final existingController = _playerController;
    if (existingController != null) {
      _handledEndedState = false;
      existingController.loadVideoById(videoId: track.videoId);
      setState(() {
        _currentTrack = track;
        _currentLocalItem = null;
        _message = null;
      });
      return;
    }

    final controller = YoutubePlayerController.fromVideoId(
      videoId: track.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        mute: false,
        enableCaption: true,
        strictRelatedVideos: true,
      ),
    );
    _attachPlayerListener(controller);

    setState(() {
      _currentTrack = track;
      _currentLocalItem = null;
      _playerController = controller;
      _message = null;
    });
  }

  void _attachPlayerListener(YoutubePlayerController controller) {
    _playerSubscription?.cancel();
    _playerSubscription = controller.stream.listen((value) {
      if (!mounted) {
        return;
      }
      if (value.playerState == PlayerState.ended && !_handledEndedState) {
        _handledEndedState = true;
        _playNextTrack();
      }
      if (value.playerState == PlayerState.playing) {
        _handledEndedState = false;
      }
    });
  }

  void _playNextTrack() {
    if (!mounted) {
      return;
    }
    final currentTrack = _currentTrack;
    if (currentTrack == null || _tracks.isEmpty) {
      return;
    }
    final currentIndex = _tracks.indexWhere(
      (track) => track.videoId == currentTrack.videoId,
    );
    final nextIndex = currentIndex < 0
        ? 0
        : (currentIndex + 1) % _tracks.length;
    _playTrack(_tracks[nextIndex]);
  }

  Future<void> _pickLocalMedia() async {
    final user = _signedInUser;
    if (user == null) {
      setState(() {
        _selectedTab = 2;
        _message = 'Sign in first, then upload your own MP3 or video.';
      });
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const [
        'mp3',
        'm4a',
        'aac',
        'wav',
        'mp4',
        'mov',
        'mkv',
      ],
    );
    if (result == null) {
      return;
    }

    final uploaded = result.files.where((file) => file.path != null).map((
      file,
    ) {
      final extension = (file.extension ?? '').toLowerCase();
      final type = _isVideoExtension(extension)
          ? LocalMediaType.video
          : LocalMediaType.audio;
      return LocalMediaItem(
        name: file.name,
        path: file.path!,
        type: type,
        ownerName: user.name,
      );
    }).toList();

    if (uploaded.isEmpty) {
      return;
    }

    setState(() {
      _localItems.insertAll(0, uploaded);
      _selectedTab = 1;
      _message =
          'Added ${uploaded.length} personal file${uploaded.length == 1 ? '' : 's'}.';
    });
    await _saveLibrary();
  }

  Future<void> _playLocalItem(LocalMediaItem item) async {
    _playerController?.pauseVideo();
    _currentTrack = null;

    await _audioPlayer.stop();
    await _videoController?.dispose();
    _videoController = null;

    if (item.type == LocalMediaType.audio) {
      await _audioPlayer.setFilePath(item.path);
      await _audioPlayer.play();
    } else {
      final controller = VideoPlayerController.file(File(item.path));
      await controller.initialize();
      await controller.play();
      _videoController = controller;
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _currentLocalItem = item;
      _selectedTab = 1;
      _message = null;
    });
  }

  Future<void> _toggleLocalPlayback() async {
    final item = _currentLocalItem;
    if (item == null) {
      return;
    }

    if (item.type == LocalMediaType.audio) {
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
      return;
    }

    final controller = _videoController;
    if (controller == null) {
      return;
    }
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _stopLocalPlayback() async {
    _currentLocalItem = null;
    _isLocalAudioPlaying = false;
    await _audioPlayer.stop();
    await _videoController?.pause();
    await _videoController?.dispose();
    _videoController = null;
  }

  Future<void> _signIn({required String name, required String email}) async {
    final trimmed = name.trim().isEmpty ? 'student' : name.trim();
    final normalizedEmail = email.trim().isEmpty
        ? '${trimmed.toLowerCase().replaceAll(' ', '')}@mucsic.local'
        : email.trim();
    setState(() {
      _signedInUser = DemoUserProfile(
        name: trimmed,
        email: normalizedEmail,
        bio: 'Music lover and Mucsic listener',
      );
      _message = 'Signed in as $trimmed.';
    });
    await _saveLibrary();
  }

  Future<void> _register({required String name, required String email}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final normalizedEmail = email.trim().isEmpty
        ? '${trimmed.toLowerCase().replaceAll(' ', '')}@mucsic.local'
        : email.trim();
    setState(() {
      _signedInUser = DemoUserProfile(
        name: trimmed,
        email: normalizedEmail,
        bio: 'New Mucsic member',
      );
      _selectedTab = 2;
      _message = 'Account created. Welcome, $trimmed.';
    });
    await _saveLibrary();
  }

  Future<void> _signOut() async {
    await _stopLocalPlayback();
    setState(() {
      _signedInUser = null;
      _localItems.clear();
      _favoriteIds.clear();
      _playlists = DemoLocalStorage._defaultPlaylists();
      _message = 'Signed out. Personal files were cleared for this demo.';
    });
    await _saveLibrary();
  }

  Future<void> _toggleFavorite(String itemId, String title) async {
    if (_signedInUser == null) {
      setState(() {
        _selectedTab = 2;
        _message = 'Sign in before saving favorites.';
      });
      return;
    }
    setState(() {
      if (_favoriteIds.contains(itemId)) {
        _favoriteIds.remove(itemId);
        _message = 'Removed "$title" from favorites.';
      } else {
        _favoriteIds.add(itemId);
        _message = 'Added "$title" to favorites.';
      }
    });
    await _saveLibrary();
  }

  Future<void> _addToPlaylist(String itemId, String title) async {
    if (_signedInUser == null) {
      setState(() {
        _selectedTab = 2;
        _message = 'Sign in before adding songs to playlists.';
      });
      return;
    }
    final firstPlaylist = _playlists.isEmpty
        ? const DemoPlaylist(
            name: 'Favorites Mix',
            description: 'Playlist demo for saved songs',
            itemIds: [],
          )
        : _playlists.first;
    if (firstPlaylist.itemIds.contains(itemId)) {
      setState(
        () => _message = '"$title" is already in ${firstPlaylist.name}.',
      );
      return;
    }
    final updated = DemoPlaylist(
      name: firstPlaylist.name,
      description: firstPlaylist.description,
      itemIds: [...firstPlaylist.itemIds, itemId],
    );
    setState(() {
      if (_playlists.isEmpty) {
        _playlists = [updated];
      } else {
        _playlists = [updated, ..._playlists.skip(1)];
      }
      _message = 'Added "$title" to ${updated.name}.';
    });
    await _saveLibrary();
  }

  String _trackId(YouTubeTrack track) => 'yt:${track.videoId}';

  String _localItemId(LocalMediaItem item) => 'local:${item.path}';

  String _titleForItemId(String itemId) {
    if (itemId.startsWith('yt:')) {
      final videoId = itemId.substring(3);
      for (final track in _tracks) {
        if (track.videoId == videoId) {
          return track.title;
        }
      }
      return 'YouTube song';
    }
    if (itemId.startsWith('local:')) {
      final path = itemId.substring(6);
      for (final item in _localItems) {
        if (item.path == path) {
          return item.name;
        }
      }
      return 'Personal file';
    }
    return 'Saved item';
  }

  List<LocalMediaItem> get _favoriteLocalItems {
    return _localItems
        .where((item) => _favoriteIds.contains(_localItemId(item)))
        .toList();
  }

  List<YouTubeTrack> get _favoriteTracks {
    return _tracks
        .where((track) => _favoriteIds.contains(_trackId(track)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _buildCurrentTab()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        backgroundColor: _surfaceColor,
        indicatorColor: _highlightColor,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.public),
            selectedIcon: Icon(Icons.public),
            label: 'YouTube',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: 'My Music',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
      floatingActionButton: _selectedTab == 1
          ? FloatingActionButton.extended(
              onPressed: _pickLocalMedia,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload'),
            )
          : null,
    );
  }

  Widget _buildCurrentTab() {
    return switch (_selectedTab) {
      0 => _buildYouTubeTab(),
      1 => _buildLocalLibraryTab(),
      _ => _buildAccountTab(),
    };
  }

  Widget _buildYouTubeTab() {
    final player = _playerController;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      children: [
        _HomeHeader(
          subtitle: 'Vietnamese music videos from YouTube',
          trailing: IconButton.filledTonal(
            onPressed: _openSearch,
            icon: const Icon(Icons.search),
            tooltip: 'Search',
          ),
        ),
        const SizedBox(height: 14),
        if (_currentTrack == null)
          _StartSearchPanel(onSearch: _openSearch)
        else ...[
          _PlayerPanel(
            track: _currentTrack,
            player: player == null
                ? const SizedBox.shrink()
                : YoutubePlayer(controller: player),
          ),
          const SizedBox(height: 18),
        ],
        if (_message != null) _StatusBanner(message: _message!),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_tracks.isNotEmpty) ...[
          _ResultsHeader(
            count: _tracks.length,
            query: _activeQuery,
            hasPlayer: _currentTrack != null,
          ),
          const SizedBox(height: 10),
          ..._tracks.indexed.map(
            (entry) => _TrackTile(
              track: entry.$2,
              index: entry.$1 + 1,
              isSelected: entry.$2.videoId == _currentTrack?.videoId,
              isFavorite: _favoriteIds.contains(_trackId(entry.$2)),
              onTap: () => _playTrack(entry.$2),
              onToggleFavorite: () =>
                  _toggleFavorite(_trackId(entry.$2), entry.$2.title),
              onAddToPlaylist: () =>
                  _addToPlaylist(_trackId(entry.$2), entry.$2.title),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLocalLibraryTab() {
    final videoController = _videoController;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 96),
      children: [
        _HomeHeader(
          subtitle: _signedInUser == null
              ? 'Sign in to upload MP3 or video files'
              : 'Library for ${_signedInUser!.name}',
          trailing: IconButton.filledTonal(
            onPressed: _pickLocalMedia,
            icon: const Icon(Icons.upload_file),
            tooltip: 'Upload file',
          ),
        ),
        const SizedBox(height: 14),
        if (_message != null) _StatusBanner(message: _message!),
        if (_currentLocalItem != null) ...[
          _LocalPlayerPanel(
            item: _currentLocalItem!,
            isAudioPlaying: _isLocalAudioPlaying,
            videoController: videoController,
            onTogglePlayback: _toggleLocalPlayback,
          ),
          const SizedBox(height: 18),
        ],
        if (_signedInUser == null)
          _DemoPromptPanel(
            icon: Icons.lock_outline,
            title: 'Demo sign-in required',
            message: 'Use the Account tab to sign in, then upload local media.',
            actionLabel: 'Go to Account',
            onAction: () => setState(() => _selectedTab = 2),
          )
        else
          _LibrarySections(
            selectedIndex: _librarySection,
            onSelected: (index) => setState(() => _librarySection = index),
            uploadedCount: _localItems.length,
            favoriteCount: _favoriteIds.length,
            playlistCount: _playlists.length,
          ),
        if (_signedInUser != null) const SizedBox(height: 14),
        if (_signedInUser != null) _buildSelectedLibrarySection(),
      ],
    );
  }

  Widget _buildSelectedLibrarySection() {
    if (_librarySection == 1) {
      if (_favoriteIds.isEmpty) {
        return _DemoPromptPanel(
          icon: Icons.favorite_border,
          title: 'No favorites yet',
          message: 'Tap the heart button on a YouTube result or personal file.',
          actionLabel: 'Search songs',
          onAction: () => setState(() => _selectedTab = 0),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Favorite songs'),
          const SizedBox(height: 10),
          ..._favoriteTracks.indexed.map(
            (entry) => _TrackTile(
              track: entry.$2,
              index: entry.$1 + 1,
              isSelected: entry.$2.videoId == _currentTrack?.videoId,
              isFavorite: true,
              onTap: () => _playTrack(entry.$2),
              onToggleFavorite: () =>
                  _toggleFavorite(_trackId(entry.$2), entry.$2.title),
              onAddToPlaylist: () =>
                  _addToPlaylist(_trackId(entry.$2), entry.$2.title),
            ),
          ),
          ..._favoriteLocalItems.indexed.map(
            (entry) => _LocalMediaTile(
              item: entry.$2,
              index: _favoriteTracks.length + entry.$1 + 1,
              isSelected: entry.$2.path == _currentLocalItem?.path,
              isFavorite: true,
              onTap: () => _playLocalItem(entry.$2),
              onToggleFavorite: () =>
                  _toggleFavorite(_localItemId(entry.$2), entry.$2.name),
              onAddToPlaylist: () =>
                  _addToPlaylist(_localItemId(entry.$2), entry.$2.name),
            ),
          ),
          if (_favoriteTracks.isEmpty && _favoriteLocalItems.isEmpty)
            const _MutedNote(
              'Saved YouTube favorites reappear here after the song is loaded in search results.',
            ),
        ],
      );
    }

    if (_librarySection == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Albums and playlists'),
          const SizedBox(height: 10),
          ..._playlists.map(
            (playlist) => _PlaylistCard(
              playlist: playlist,
              titleForItemId: _titleForItemId,
            ),
          ),
        ],
      );
    }

    if (_localItems.isEmpty) {
      return _DemoPromptPanel(
        icon: Icons.upload_file,
        title: 'Upload your first file',
        message: 'Choose MP3, M4A, WAV, MP4, MOV, or MKV from this device.',
        actionLabel: 'Upload media',
        onAction: _pickLocalMedia,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('My uploaded files'),
        const SizedBox(height: 10),
        ..._localItems.indexed.map(
          (entry) => _LocalMediaTile(
            item: entry.$2,
            index: entry.$1 + 1,
            isSelected: entry.$2.path == _currentLocalItem?.path,
            isFavorite: _favoriteIds.contains(_localItemId(entry.$2)),
            onTap: () => _playLocalItem(entry.$2),
            onToggleFavorite: () =>
                _toggleFavorite(_localItemId(entry.$2), entry.$2.name),
            onAddToPlaylist: () =>
                _addToPlaylist(_localItemId(entry.$2), entry.$2.name),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      children: [
        _HomeHeader(
          subtitle: 'Demo account for personal music',
          trailing: IconButton.filledTonal(
            onPressed: _signedInUser == null ? null : () => _signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ),
        const SizedBox(height: 14),
        if (_message != null) _StatusBanner(message: _message!),
        if (_signedInUser == null)
          _AuthPanel(
            onSignIn: (name, email) => _signIn(name: name, email: email),
            onRegister: (name, email) => _register(name: name, email: email),
          )
        else
          _AccountPanel(
            user: _signedInUser!,
            uploadCount: _localItems.length,
            favoriteCount: _favoriteIds.length,
            playlistCount: _playlists.length,
            onUpload: () {
              setState(() => _selectedTab = 1);
              _pickLocalMedia();
            },
            onSignOut: () => _signOut(),
          ),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.subtitle, required this.trailing});

  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mucsic',
                style: TextStyle(fontSize: 31, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}

class _StartSearchPanel extends StatelessWidget {
  const _StartSearchPanel({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _surfaceColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onSearch,
        child: Container(
          height: 168,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 42, color: _accentColor),
              SizedBox(height: 12),
              Text(
                'Search for a song',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 6),
              Text(
                'Find Vietnamese music videos, then tap a result to play.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerPanel extends StatelessWidget {
  const _PlayerPanel({required this.track, required this.player});

  final YouTubeTrack? track;
  final Widget player;

  @override
  Widget build(BuildContext context) {
    if (track == null) {
      return Container(
        height: 190,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_circle_outline, size: 42, color: _accentColor),
              SizedBox(height: 10),
              Text(
                'Choose a YouTube result to play',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    final activeTrack = track!;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: player),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _accentColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.equalizer, color: Colors.black),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeTrack.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1.22,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      activeTrack.channel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(message, style: const TextStyle(color: Colors.white70)),
    );
  }
}

class _LocalPlayerPanel extends StatelessWidget {
  const _LocalPlayerPanel({
    required this.item,
    required this.isAudioPlaying,
    required this.videoController,
    required this.onTogglePlayback,
  });

  final LocalMediaItem item;
  final bool isAudioPlaying;
  final VideoPlayerController? videoController;
  final VoidCallback onTogglePlayback;

  @override
  Widget build(BuildContext context) {
    final isVideo = item.type == LocalMediaType.video;
    final controller = videoController;
    final isPlaying = isVideo
        ? controller?.value.isPlaying ?? false
        : isAudioPlaying;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isVideo && controller != null && controller.value.isInitialized)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            )
          else
            Container(
              height: 156,
              decoration: BoxDecoration(
                color: _surfaceColorAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.album, size: 54, color: _accentColor),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton.filled(
                onPressed: onTogglePlayback,
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                tooltip: isPlaying ? 'Pause' : 'Play',
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isVideo ? 'Personal video' : 'Personal audio',
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DemoPromptPanel extends StatelessWidget {
  const _DemoPromptPanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: _accentColor),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.arrow_forward),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _LibrarySections extends StatelessWidget {
  const _LibrarySections({
    required this.selectedIndex,
    required this.onSelected,
    required this.uploadedCount,
    required this.favoriteCount,
    required this.playlistCount,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final int uploadedCount;
  final int favoriteCount;
  final int playlistCount;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      selected: {selectedIndex},
      onSelectionChanged: (selection) => onSelected(selection.first),
      segments: [
        ButtonSegment(
          value: 0,
          icon: const Icon(Icons.upload_file),
          label: Text('Uploaded ($uploadedCount)'),
        ),
        ButtonSegment(
          value: 1,
          icon: const Icon(Icons.favorite),
          label: Text('Favorites ($favoriteCount)'),
        ),
        ButtonSegment(
          value: 2,
          icon: const Icon(Icons.queue_music),
          label: Text('Playlists ($playlistCount)'),
        ),
      ],
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({required this.playlist, required this.titleForItemId});

  final DemoPlaylist playlist;
  final String Function(String itemId) titleForItemId;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.album, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlist.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${playlist.itemIds.length} song${playlist.itemIds.length == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.white60),
                ),
                if (playlist.itemIds.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...playlist.itemIds
                      .take(3)
                      .map(
                        (id) => Text(
                          titleForItemId(id),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MutedNote extends StatelessWidget {
  const _MutedNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(text, style: const TextStyle(color: Colors.white54)),
    );
  }
}

class _AuthPanel extends StatefulWidget {
  const _AuthPanel({required this.onSignIn, required this.onRegister});

  final void Function(String name, String email) onSignIn;
  final void Function(String name, String email) onRegister;

  @override
  State<_AuthPanel> createState() => _AuthPanelState();
}

class _AuthPanelState extends State<_AuthPanel> {
  final _nameController = TextEditingController(text: 'student');
  final _emailController = TextEditingController(text: 'student@mucsic.local');
  final _passwordController = TextEditingController(text: '123456');
  bool _isRegister = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_isRegister) {
      widget.onRegister(_nameController.text, _emailController.text);
    } else {
      final name = _nameController.text.trim().isEmpty
          ? 'student'
          : _nameController.text;
      final email = _emailController.text.trim().isEmpty
          ? 'student@mucsic.local'
          : _emailController.text;
      widget.onSignIn(name, email);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<bool>(
            selected: {_isRegister},
            onSelectionChanged: (value) {
              setState(() => _isRegister = value.first);
            },
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.login),
                label: Text('Login'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.person_add),
                label: Text('Register'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _isRegister ? 'Create account' : 'Welcome back',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: _authInputDecoration('Display name', Icons.person),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: _authInputDecoration('Email', Icons.email),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _passwordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: _authInputDecoration('Password', Icons.lock),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _submit,
            icon: Icon(_isRegister ? Icons.person_add : Icons.login),
            label: Text(_isRegister ? 'Create account' : 'Login'),
          ),
          const SizedBox(height: 10),
          const Text(
            'Demo login: just tap Login. Password is not checked yet.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  InputDecoration _authInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: _surfaceColorAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _SignInPanel extends StatefulWidget {
  const _SignInPanel({required this.onSignIn});

  final ValueChanged<String> onSignIn;

  @override
  State<_SignInPanel> createState() => _SignInPanelState();
}

class _SignInPanelState extends State<_SignInPanel> {
  final _nameController = TextEditingController(text: 'student');

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Sign in',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.done,
            onSubmitted: widget.onSignIn,
            decoration: InputDecoration(
              labelText: 'Name',
              prefixIcon: const Icon(Icons.person),
              filled: true,
              fillColor: _surfaceColorAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => widget.onSignIn(_nameController.text),
            icon: const Icon(Icons.login),
            label: const Text('Continue'),
          ),
          const SizedBox(height: 10),
          const Text(
            'This is local demo login. No server, password, or billing.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _AccountPanel extends StatelessWidget {
  const _AccountPanel({
    required this.user,
    required this.uploadCount,
    required this.favoriteCount,
    required this.playlistCount,
    required this.onUpload,
    required this.onSignOut,
  });

  final DemoUserProfile user;
  final int uploadCount;
  final int favoriteCount;
  final int playlistCount;
  final VoidCallback onUpload;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: _accentColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    user.name.isEmpty ? 'U' : user.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white60),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.bio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ProfileStat(
                  label: 'Uploads',
                  value: uploadCount.toString(),
                  icon: Icons.upload_file,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ProfileStat(
                  label: 'Favorites',
                  value: favoriteCount.toString(),
                  icon: Icons.favorite,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ProfileStat(
                  label: 'Playlists',
                  value: playlistCount.toString(),
                  icon: Icons.queue_music,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _surfaceColorAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: _accentColor, size: 20),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _LocalMediaTile extends StatelessWidget {
  const _LocalMediaTile({
    required this.item,
    required this.index,
    required this.isSelected,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onAddToPlaylist,
  });

  final LocalMediaItem item;
  final int index;
  final bool isSelected;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onAddToPlaylist;

  @override
  Widget build(BuildContext context) {
    final isVideo = item.type == LocalMediaType.video;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isSelected ? _highlightColor : _surfaceColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: _surfaceColorAlt,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isVideo ? Icons.movie : Icons.music_note,
                    color: _accentColor,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isSelected) ...[
                        const Text(
                          'Now playing',
                          style: TextStyle(
                            color: _accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                      ],
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isVideo ? 'Video file' : 'Audio file',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onToggleFavorite,
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                  ),
                  color: isFavorite ? _accentColor : Colors.white70,
                  tooltip: isFavorite ? 'Remove favorite' : 'Add favorite',
                ),
                IconButton(
                  onPressed: onAddToPlaylist,
                  icon: const Icon(Icons.playlist_add),
                  color: Colors.white70,
                  tooltip: 'Add to playlist',
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected ? _accentColor : _surfaceColorAlt,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSelected ? Icons.graphic_eq : Icons.play_arrow,
                    color: isSelected ? Colors.black : Colors.white,
                    size: 19,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchPage extends StatefulWidget {
  const _SearchPage({
    required this.initialQuery,
    required this.history,
    required this.tracks,
  });

  final String initialQuery;
  final List<String> history;
  final List<YouTubeTrack> tracks;

  @override
  State<_SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<_SearchPage> {
  late final TextEditingController _controller;
  String _query = '';

  static const _suggestions = [
    'bray',
    'vpop viet nam',
    'son tung mtp',
    'rpt mck',
    'hoang thuy linh',
    'amee',
    'hieuthuhai',
    'my tam',
    'den vau',
    'soobin',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _query = widget.initialQuery;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> get _visibleTextSuggestions {
    final normalizedQuery = _query.trim().toLowerCase();
    final combined = <String>[...widget.history, ..._suggestions];
    final unique = <String>[];
    for (final item in combined) {
      if (unique.any((value) => value.toLowerCase() == item.toLowerCase())) {
        continue;
      }
      if (normalizedQuery.isEmpty ||
          item.toLowerCase().contains(normalizedQuery)) {
        unique.add(item);
      }
    }
    return unique.take(8).toList();
  }

  List<YouTubeTrack> get _visibleTrackSuggestions {
    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return widget.tracks.take(4).toList();
    }
    return widget.tracks
        .where((track) {
          return track.title.toLowerCase().contains(normalizedQuery) ||
              track.channel.toLowerCase().contains(normalizedQuery);
        })
        .take(5)
        .toList();
  }

  void _submit(String query) {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return;
    }
    Navigator.of(context).pop(normalizedQuery);
  }

  @override
  Widget build(BuildContext context) {
    final trackSuggestions = _visibleTrackSuggestions;
    final textSuggestions = _visibleTextSuggestions;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onChanged: (value) => setState(() => _query = value),
                    onSubmitted: _submit,
                    decoration: InputDecoration(
                      hintText: 'Search songs, artists, MV',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        onPressed: () => _submit(_controller.text),
                        icon: const Icon(Icons.arrow_forward),
                        tooltip: 'Search',
                      ),
                      filled: true,
                      fillColor: _surfaceColorAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            if (widget.history.isNotEmpty) ...[
              const _SectionLabel('Search history'),
              const SizedBox(height: 8),
              ...widget.history
                  .take(5)
                  .map(
                    (item) => _SearchTextTile(
                      icon: Icons.history,
                      text: item,
                      onTap: () => _submit(item),
                    ),
                  ),
              const SizedBox(height: 16),
            ],
            if (textSuggestions.isNotEmpty) ...[
              const _SectionLabel('Suggestions'),
              const SizedBox(height: 8),
              ...textSuggestions.map(
                (item) => _SearchTextTile(
                  icon: Icons.trending_up,
                  text: item,
                  onTap: () => _submit(item),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (trackSuggestions.isNotEmpty) ...[
              const _SectionLabel('Song suggestions'),
              const SizedBox(height: 8),
              ...trackSuggestions.map(
                (track) => _SearchTrackSuggestionTile(
                  track: track,
                  onTap: () => _submit(track.title),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
    );
  }
}

class _SearchTextTile extends StatelessWidget {
  const _SearchTextTile({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.white54),
      title: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.north_west, size: 18, color: Colors.white38),
      onTap: onTap,
    );
  }
}

class _SearchTrackSuggestionTile extends StatelessWidget {
  const _SearchTrackSuggestionTile({required this.track, required this.onTap});

  final YouTubeTrack track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _ThumbnailImage(imageUrl: track.thumbnailUrl),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        track.channel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({
    required this.count,
    required this.query,
    required this.hasPlayer,
  });

  final int count;
  final String query;
  final bool hasPlayer;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasPlayer ? 'Up next' : 'Search results',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                query,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
        Text(
          '$count videos',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({
    required this.track,
    required this.index,
    required this.isSelected,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onAddToPlaylist,
  });

  final YouTubeTrack track;
  final int index;
  final bool isSelected;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onAddToPlaylist;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isSelected ? _highlightColor : _surfaceColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _ThumbnailImage(imageUrl: track.thumbnailUrl),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isSelected) ...[
                        const Text(
                          'Now playing',
                          style: TextStyle(
                            color: _accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                      ],
                      Text(
                        track.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        track.channel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onToggleFavorite,
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                  ),
                  color: isFavorite ? _accentColor : Colors.white70,
                  tooltip: isFavorite ? 'Remove favorite' : 'Add favorite',
                ),
                IconButton(
                  onPressed: onAddToPlaylist,
                  icon: const Icon(Icons.playlist_add),
                  color: Colors.white70,
                  tooltip: 'Add to playlist',
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected ? _accentColor : _surfaceColorAlt,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSelected ? Icons.graphic_eq : Icons.play_arrow,
                    color: isSelected ? Colors.black : Colors.white,
                    size: 19,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThumbnailImage extends StatelessWidget {
  const _ThumbnailImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return const _FallbackThumbnail();
    }

    return Image.network(
      imageUrl,
      width: 72,
      height: 54,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _FallbackThumbnail(),
    );
  }
}

class _FallbackThumbnail extends StatelessWidget {
  const _FallbackThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 54,
      color: const Color(0xFF14B8A6),
      child: const Icon(Icons.play_arrow, color: Colors.black),
    );
  }
}

String _decodeHtml(String value) {
  return value
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
}

bool _isVideoExtension(String extension) {
  return const {'mp4', 'mov', 'mkv'}.contains(extension.toLowerCase());
}
