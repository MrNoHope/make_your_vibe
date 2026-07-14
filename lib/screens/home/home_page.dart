import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../controllers/vibe_controller.dart';
import '../../core/app_colors.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../../models/system_album.dart';
import '../../services/library_gateway.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/song_widgets.dart';

class HomePage extends StatefulWidget {
  final VibeController controller;
  final VoidCallback onOpenPlayer;
  final VoidCallback onOpenSearch;

  const HomePage({
    super.key,
    required this.controller,
    required this.onOpenPlayer,
    required this.onOpenSearch,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Map<String, List<Song>> _albumCache = {};
  String _loadingAlbumId = '';

  List<_AlbumShelfData> get _albumShelves => [
        _AlbumShelfData(
          title: 'Noi bat',
          albums: _albumsByIds([
            'thien-ha',
            'top-100',
            'rap-viet',
            'son-tung',
          ]),
        ),
        _AlbumShelfData(
          title: 'Dòng nhạc cho bạn',
          albums: _albumsByIds([
            'chill-vpop',
            'ballad',
            'remix',
            'study',
          ]),
        ),
        _AlbumShelfData(
          title: 'Nghe theo vibe',
          albums: _albumsByIds([
            'study',
            'chill-vpop',
            'ballad',
            'rap-viet',
          ]),
        ),
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kIsWeb) {
        widget.controller.loadHomeSongs();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return PageScroll(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TopBar(
                title: 'Make Your Vibe',
                action: IconButton(
                  tooltip: 'Tìm kiếm',
                  onPressed: widget.onOpenSearch,
                  icon: const Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 14),
              if (widget.controller.listeningHistory.isNotEmpty) ...[
                _RecentSongShelf(
                  songs: widget.controller.listeningHistory,
                  activeId: widget.controller.currentSong?.id,
                  activePlaying: widget.controller.isPlaying,
                  activeBusy: widget.controller.resolving,
                  onClear: widget.controller.clearListeningHistory,
                  onSongTap: (song) async {
                    await widget.controller.playSong(
                      song,
                      queue: widget.controller.listeningHistory,
                    );
                    if (mounted) {
                      widget.onOpenPlayer();
                    }
                  },
                  onActiveToggle: widget.controller.togglePlay,
                ),
                const SizedBox(height: 20),
              ],
              ..._albumShelves.map(
                (shelf) => _FeaturedAlbumShelf(
                  title: shelf.title,
                  albums: shelf.albums,
                  loadingId: _loadingAlbumId,
                  onAlbumTap: openFeaturedAlbum,
                ),
              ),
              const SizedBox(height: 4),
              if (widget.controller.loadingHome)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (widget.controller.homeSongs.isNotEmpty)
                SongList(
                  songs: widget.controller.homeSongs,
                  activeId: widget.controller.currentSong?.id,
                  activePlaying: widget.controller.isPlaying,
                  activeBusy: widget.controller.resolving,
                  onSongTap: (song) async {
                    await widget.controller.playSong(
                      song,
                      queue: widget.controller.homeSongs,
                    );
                    if (mounted) {
                      widget.onOpenPlayer();
                    }
                  },
                  onActiveToggle: widget.controller.togglePlay,
                  onActiveOpen: widget.onOpenPlayer,
                  onSongAddToAlbum: showAddToPersonalAlbumDialog,
                ),
              if (widget.controller.errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                BackendNotice(
                  icon: Icons.error_outline_rounded,
                  title: 'Lỗi phát nhạc',
                  message: widget.controller.errorMessage,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> openFeaturedAlbum(SystemAlbum album) async {
    if (_loadingAlbumId.isNotEmpty) {
      return;
    }

    var songs = _albumCache[album.id];

    if (songs == null) {
      setState(() {
        _loadingAlbumId = album.id;
      });

      try {
        songs = await widget.controller.music.searchTracks(album.query);
        _albumCache[album.id] = songs;
      } catch (error) {
        showSnack('Không tải được album: $error');
        return;
      } finally {
        if (mounted) {
          setState(() {
            _loadingAlbumId = '';
          });
        }
      }
    }

    if (!mounted) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      builder: (sheetContext) {
        void openPlayerFromSheet() {
          Navigator.of(sheetContext).pop();
          if (mounted) {
            widget.onOpenPlayer();
          }
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CoverImage(
                      url: album.coverUrl,
                      size: 58,
                      radius: 8,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            album.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            album.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.soft),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: SingleChildScrollView(
                    child: SongList(
                      songs: songs!,
                      activeId: widget.controller.currentSong?.id,
                      activePlaying: widget.controller.isPlaying,
                      activeBusy: widget.controller.resolving,
                      onSongTap: (song) async {
                        await widget.controller.playSong(song, queue: songs);
                        openPlayerFromSheet();
                      },
                      onActiveToggle: widget.controller.togglePlay,
                      onActiveOpen: openPlayerFromSheet,
                      onSongAddToAlbum: showAddToPersonalAlbumDialog,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> showAddToPersonalAlbumDialog(Song song) async {
    if (!libraryGateway.isConfigured) {
      showSnack('Chưa cấu hình Firebase.');
      return;
    }

    final newAlbumController = TextEditingController();

    try {
      final availableAlbums = await libraryGateway.getAlbums();

      if (!mounted) {
        return;
      }

      final message = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          var busy = false;
          var createNew = availableAlbums.isEmpty;
          var selectedAlbumId =
              availableAlbums.isEmpty ? '' : availableAlbums.first.id;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              final selectedAlbum = _albumById(
                availableAlbums,
                selectedAlbumId,
              );

              return AlertDialog(
                backgroundColor: AppColors.card,
                title: const Text('Thêm vào album cá nhân'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      if (availableAlbums.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          initialValue: createNew ? '__new__' : selectedAlbumId,
                          decoration: const InputDecoration(
                            labelText: 'Album cá nhân',
                          ),
                          items: [
                            ...availableAlbums.map(
                              (album) => DropdownMenuItem(
                                value: album.id,
                                child: Text(album.title),
                              ),
                            ),
                            const DropdownMenuItem(
                              value: '__new__',
                              child: Text('Tạo album mới'),
                            ),
                          ],
                          onChanged: busy
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    createNew = value == '__new__';
                                    selectedAlbumId =
                                        createNew ? '' : value ?? '';
                                  });
                                },
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (createNew)
                        TextField(
                          controller: newAlbumController,
                          decoration: const InputDecoration(
                            labelText: 'Tên album cá nhân mới',
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed:
                        busy ? null : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Hủy'),
                  ),
                  FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () async {
                            if (createNew &&
                                newAlbumController.text.trim().isEmpty) {
                              showSnack('Nhập tên album.');
                              return;
                            }

                            setDialogState(() {
                              busy = true;
                            });

                            try {
                              final targetAlbum = createNew
                                  ? await libraryGateway.createAlbum(
                                      title: newAlbumController.text,
                                    )
                                  : selectedAlbum;

                              if (targetAlbum == null) {
                                throw const LibraryGatewayException(
                                  'Chọn album.',
                                );
                              }

                              await libraryGateway.saveOnlineSongToAlbum(
                                song: song,
                                albumId: targetAlbum.id,
                                albumTitle: targetAlbum.title,
                              );

                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop(
                                  'Đã thêm vào ${targetAlbum.title}.',
                                );
                              }
                            } catch (error) {
                              setDialogState(() {
                                busy = false;
                              });
                              showSnack('$error');
                            }
                          },
                    icon: const Icon(Icons.playlist_add_rounded),
                    label: const Text('Thêm'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (message != null && message.isNotEmpty) {
        showSnack(message);
      }
    } catch (error) {
      showSnack('$error');
    } finally {
      newAlbumController.dispose();
    }
  }

  Playlist? _albumById(List<Playlist> albums, String id) {
    for (final album in albums) {
      if (album.id == id) {
        return album;
      }
    }
    return null;
  }

  List<SystemAlbum> _albumsByIds(List<String> ids) {
    return ids
        .map(
          (id) => systemAlbums.firstWhere(
            (album) => album.id == id,
          ),
        )
        .toList();
  }

  void showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _RecentSongShelf extends StatelessWidget {
  final List<Song> songs;
  final String? activeId;
  final bool activePlaying;
  final bool activeBusy;
  final ValueChanged<Song> onSongTap;
  final VoidCallback onClear;
  final VoidCallback? onActiveToggle;

  const _RecentSongShelf({
    required this.songs,
    required this.activeId,
    required this.activePlaying,
    required this.activeBusy,
    required this.onSongTap,
    required this.onClear,
    required this.onActiveToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Nghe gan day',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(
              onPressed: onClear,
              child: const Text('Xoa'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: songs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final song = songs[index];
              return _RecentSongCard(
                song: song,
                active: song.id == activeId,
                playing: activePlaying,
                busy: activeBusy,
                onTap: () => onSongTap(song),
                onToggle: onActiveToggle,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecentSongCard extends StatelessWidget {
  final Song song;
  final bool active;
  final bool playing;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback? onToggle;

  const _RecentSongCard({
    required this.song,
    required this.active,
    required this.playing,
    required this.busy,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: active && onToggle != null ? onToggle : onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 118,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox.square(
              dimension: 118,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CoverImage(
                    url: song.coverUrl,
                    size: double.infinity,
                    radius: 8,
                  ),
                  if (active)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black.withValues(alpha: 0.32),
                      ),
                    ),
                  if (active)
                    Center(
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            AppColors.green.withValues(alpha: 0.92),
                        child: Icon(
                          busy
                              ? Icons.hourglass_top_rounded
                              : playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.soft,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumShelfData {
  final String title;
  final List<SystemAlbum> albums;

  const _AlbumShelfData({
    required this.title,
    required this.albums,
  });
}

class _FeaturedAlbumShelf extends StatelessWidget {
  final String title;
  final List<SystemAlbum> albums;
  final String loadingId;
  final ValueChanged<SystemAlbum> onAlbumTap;

  const _FeaturedAlbumShelf({
    required this.title,
    required this.albums,
    required this.loadingId,
    required this.onAlbumTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 184,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: albums.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final album = albums[index];
                return _FeaturedAlbumCard(
                  album: album,
                  loading: loadingId == album.id,
                  onTap: () => onAlbumTap(album),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedAlbumCard extends StatelessWidget {
  final SystemAlbum album;
  final bool loading;
  final VoidCallback onTap;

  const _FeaturedAlbumCard({
    required this.album,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 138,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox.square(
                dimension: 138,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CoverImage(
                      url: album.coverUrl,
                      size: double.infinity,
                      radius: 8,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.02),
                            Colors.black.withValues(alpha: 0.38),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            AppColors.green.withValues(alpha: 0.92),
                        child: loading
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : Icon(
                                album.icon,
                                color: Colors.black,
                                size: 19,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              Text(
                album.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                album.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.soft,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
