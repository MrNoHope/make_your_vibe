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
              const TopBar(title: 'Tim kiem'),
              const SizedBox(height: 14),
              TextField(
                controller: textController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => submit(),
                decoration: InputDecoration(
                  hintText: 'Nhap ten bai hat, ca si...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    onPressed: submit,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 18),
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
                    );
                    if (mounted) {
                      widget.onOpenPlayer();
                    }
                  },
                  onActiveToggle: widget.controller.togglePlay,
                  onActiveOpen: widget.onOpenPlayer,
                  onSongAddToAlbum: showAddToAlbumDialog,
                ),
              if (widget.controller.errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                BackendNotice(
                  icon: Icons.error_outline_rounded,
                  title: 'Loi',
                  message: widget.controller.errorMessage,
                ),
              ],
              if (!widget.controller.searching &&
                  widget.controller.searchResults.isEmpty) ...[
                const SizedBox(height: 20),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    SearchChip(
                        label: 'Son Tung',
                        onTap: () => quickSearch('Son Tung')),
                    SearchChip(label: 'Lofi', onTap: () => quickSearch('lofi')),
                    SearchChip(
                        label: 'Chill',
                        onTap: () => quickSearch('chill music')),
                    SearchChip(
                        label: 'V-pop', onTap: () => quickSearch('vpop')),
                    SearchChip(
                        label: 'Jazz', onTap: () => quickSearch('jazz music')),
                  ],
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
      showSnack('Chua cau hinh Firebase.');
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

class SearchChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const SearchChip({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Chip(
        label: Text(label),
        labelStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
        ),
        backgroundColor: AppColors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}
