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
                  tooltip: 'Tim kiem',
                  onPressed: widget.onOpenSearch,
                  icon: const Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Album cua app',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              _FeaturedAlbumGrid(
                albums: systemAlbums,
                loadingId: _loadingAlbumId,
                onAlbumTap: openFeaturedAlbum,
              ),
              const SizedBox(height: 20),
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
                  title: 'Loi phat nhac',
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
        showSnack('Khong tai duoc album: $error');
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
      showSnack('Chua cau hinh Firebase.');
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
                title: const Text('Them vao album ca nhan'),
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
                            labelText: 'Album ca nhan',
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
                              child: Text('Tao album moi'),
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
                            labelText: 'Ten album ca nhan moi',
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed:
                        busy ? null : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Huy'),
                  ),
                  FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () async {
                            if (createNew &&
                                newAlbumController.text.trim().isEmpty) {
                              showSnack('Nhap ten album.');
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
                                  'Chon album.',
                                );
                              }

                              await libraryGateway.saveOnlineSongToAlbum(
                                song: song,
                                albumId: targetAlbum.id,
                                albumTitle: targetAlbum.title,
                              );

                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop(
                                  'Da them vao ${targetAlbum.title}.',
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
                    label: const Text('Them'),
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

  void showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _FeaturedAlbumGrid extends StatelessWidget {
  final List<SystemAlbum> albums;
  final String loadingId;
  final ValueChanged<SystemAlbum> onAlbumTap;

  const _FeaturedAlbumGrid({
    required this.albums,
    required this.loadingId,
    required this.onAlbumTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: albums.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.86,
      ),
      itemBuilder: (context, index) {
        final album = albums[index];
        return _FeaturedAlbumCard(
          album: album,
          loading: loadingId == album.id,
          onTap: () => onAlbumTap(album),
        );
      },
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
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CoverImage(
                        url: album.coverUrl,
                        size: double.infinity,
                        radius: 7,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.02),
                              Colors.black.withValues(alpha: 0.42),
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
      ),
    );
  }
}
