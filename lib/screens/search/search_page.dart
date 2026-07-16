import 'package:flutter/material.dart';

import '../../controllers/vibe_controller.dart';
import '../../core/app_colors.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../../services/library_gateway.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/song_widgets.dart';

class SearchPage extends StatefulWidget {
  final VibeController controller;
  final VoidCallback onOpenPlayer;

  const SearchPage({
    super.key,
    required this.controller,
    required this.onOpenPlayer,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController textController = TextEditingController();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    await widget.controller.searchSongs(textController.text);
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
              const TopBar(title: 'Tìm kiếm'),
              const SizedBox(height: 14),
              TextField(
                controller: textController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => submit(),
                decoration: InputDecoration(
                  hintText: 'Nhập tên bài hát, ca sĩ...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    onPressed: submit,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (!widget.controller.searching &&
                  widget.controller.searchResults.isEmpty &&
                  widget.controller.searchHistory.isNotEmpty) ...[
                _SearchHistorySection(
                  items: widget.controller.searchHistory,
                  onTap: quickSearch,
                  onRemove: widget.controller.removeSearchHistory,
                  onClear: widget.controller.clearSearchHistory,
                ),
                const SizedBox(height: 18),
              ],
              if (widget.controller.searching)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (widget.controller.searchResults.isNotEmpty)
                SongList(
                  songs: widget.controller.searchResults,
                  activeId: widget.controller.currentSong?.id,
                  activePlaying: widget.controller.isPlaying,
                  activeBusy: widget.controller.resolving,
                  onSongTap: (song) async {
                    await widget.controller.playSong(
                      song,
                      queue: widget.controller.searchResults,
                      context: PlayContextInfo(
                        type: PlayOriginType.search,
                        title: textController.text.trim().isEmpty
                            ? 'Lượt tìm kiếm gần đây'
                            : textController.text.trim(),
                      ),
                    );
                    if (mounted) {
                      widget.onOpenPlayer();
                    }
                  },
                  onActiveToggle: widget.controller.togglePlay,
                  onActiveOpen: widget.onOpenPlayer,
                  onSongAddToAlbum: showAddToAlbumDialog,
                  isSongFavorite: widget.controller.isFavoriteSong,
                  onSongFavoriteToggle: widget.controller.toggleFavoriteSong,
                ),
              if (widget.controller.errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                BackendNotice(
                  icon: Icons.error_outline_rounded,
                  title: 'Lỗi',
                  message: widget.controller.errorMessage,
                ),
              ],
              if (!widget.controller.searching &&
                  widget.controller.searchResults.isEmpty) ...[
                const SizedBox(height: 2),
                _TrendingSearchSection(
                  songs: widget.controller.homeSongs,
                  onTap: quickSearch,
                ),
              ],
            ],
          ),
        );
      },
    );
  }


  void quickSearch(String value) {
    textController.text = value;
    submit();
  }

  Future<void> showAddToAlbumDialog(Song song) async {
    if (!libraryGateway.isConfigured) {
      showSnack('Chưa cấu hình Firebase.');
      return;
    }

    final newAlbumController = TextEditingController();

    try {
      final availableAlbums = await libraryGateway.getAlbums();

      if (!mounted) return;

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

  void showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _SearchHistorySection extends StatelessWidget {
  final List<String> items;
  final ValueChanged<String> onTap;
  final ValueChanged<String> onRemove;
  final VoidCallback onClear;

  const _SearchHistorySection({
    required this.items,
    required this.onTap,
    required this.onRemove,
    required this.onClear,
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
                'Tìm kiếm gần đây',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(
              onPressed: onClear,
              child: const Text('Xóa tất cả'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Column(
          children: items
              .take(4)
              .map(
                (item) => _SearchHistoryRow(
                  label: item,
                  onTap: () => onTap(item),
                  onDeleted: () => onRemove(item),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _SearchHistoryRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback onDeleted;

  const _SearchHistoryRow({
    required this.label,
    required this.onTap,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(
              Icons.history_rounded,
              size: 20,
              color: isDark ? AppColors.soft : AppColors.lightSoft,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: onDeleted,
              tooltip: 'Xóa khỏi lịch sử',
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: isDark ? AppColors.muted : AppColors.lightMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendingSearchSection extends StatelessWidget {
  static const _fallbackEntries = [
    _TrendingSearchEntry(
      title: 'B Ray',
      subtitle: 'Rap Việt nổi bật',
      query: 'B Ray',
    ),
    _TrendingSearchEntry(
      title: 'HIEUTHUHAI',
      subtitle: 'Nghệ sĩ được nghe nhiều',
      query: 'HIEUTHUHAI',
    ),
    _TrendingSearchEntry(
      title: 'RPT MCK',
      subtitle: 'Rap và R&B Việt',
      query: 'RPT MCK',
    ),
    _TrendingSearchEntry(
      title: 'Phương Mỹ Chi',
      subtitle: 'V-Pop đang thịnh hành',
      query: 'Phương Mỹ Chi',
    ),
    _TrendingSearchEntry(
      title: 'Nhạc chill dễ ngủ',
      subtitle: 'Thư giãn buổi tối',
      query: 'nhạc chill dễ ngủ',
    ),
    _TrendingSearchEntry(
      title: 'Lofi học bài',
      subtitle: 'Tập trung và nhẹ đầu',
      query: 'lofi học bài',
    ),
  ];

  final List<Song> songs;
  final ValueChanged<String> onTap;

  const _TrendingSearchSection({
    required this.songs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final trendingEntries = _trendingEntries(songs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(
              child: Text(
                'Nhạc đang xu hướng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Icon(
              Icons.trending_up_rounded,
              size: 21,
              color: AppColors.green,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...trendingEntries.indexed.map(
          (entry) {
            final index = entry.$1;
            final trend = entry.$2;
            return _TrendingSearchRow(
              rank: index + 1,
              entry: trend,
              onTap: () => onTap(trend.query),
            );
          },
        ),
      ],
    );
  }

  List<_TrendingSearchEntry> _trendingEntries(List<Song> source) {
    final seen = <String>{};
    final result = <_TrendingSearchEntry>[];

    for (final song in source) {
      final title = song.title.trim();
      final key = title.toLowerCase();
      if (title.isEmpty || !seen.add(key)) {
        continue;
      }
      result.add(
        _TrendingSearchEntry(
          title: title,
          subtitle: song.artist.trim(),
          query: title,
        ),
      );
      if (result.length == 6) {
        break;
      }
    }

    return result.isEmpty ? _fallbackEntries : result;
  }
}

class _TrendingSearchEntry {
  final String title;
  final String subtitle;
  final String query;

  const _TrendingSearchEntry({
    required this.title,
    required this.subtitle,
    required this.query,
  });
}

class _TrendingSearchRow extends StatelessWidget {
  final int rank;
  final _TrendingSearchEntry entry;
  final VoidCallback onTap;

  const _TrendingSearchRow({
    required this.rank,
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryColor = isDark ? AppColors.soft : AppColors.lightSoft;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: rank <= 3 ? AppColors.green : secondaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (entry.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.north_west_rounded,
              size: 17,
              color: isDark ? AppColors.muted : AppColors.lightMuted,
            ),
          ],
        ),
      ),
    );
  }
}
