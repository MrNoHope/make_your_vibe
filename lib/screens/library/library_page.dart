import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as file_path;

import '../../controllers/vibe_controller.dart';
import '../../core/app_colors.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../../services/library_gateway.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/song_widgets.dart';

class LibraryPage extends StatefulWidget {
  final VibeController controller;
  final VoidCallback onOpenPlayer;
  final VoidCallback onOpenSearch;

  const LibraryPage({
    super.key,
    required this.controller,
    required this.onOpenPlayer,
    required this.onOpenSearch,
  });

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  bool loading = true;
  bool configured = libraryGateway.isConfigured;
  String errorMessage = '';
  List<Playlist> albums = [];
  List<Song> songs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadLibrary();
    });
  }

  Future<void> loadLibrary() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      configured = libraryGateway.isConfigured;
      errorMessage = '';
    });

    if (!libraryGateway.isConfigured) {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
      return;
    }

    try {
      final loadedAlbums = await libraryGateway.getAlbums();
      final loadedSongs = await libraryGateway.getSongs();

      if (!mounted) return;
      setState(() {
        albums = loadedAlbums;
        songs = loadedSongs;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage = '$error';
      });
    }
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
                title: 'Thu vien ca nhan',
                action: IconButton(
                  tooltip: 'Tim kiem',
                  onPressed: widget.onOpenSearch,
                  icon: const Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
              if (!configured) ...[
                const BackendNotice(
                  icon: Icons.cloud_off_rounded,
                  title: 'Chua cau hinh Firebase',
                  message: 'Them google-services.json va Firebase options.',
                ),
              ] else ...[
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    LibraryActionButton(
                      icon: Icons.add_rounded,
                      label: 'Tao album',
                      onTap: showCreateAlbumDialog,
                    ),
                    LibraryActionButton(
                      icon: Icons.upload_file_rounded,
                      label: 'Upload',
                      onTap: showUploadSongDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  if (errorMessage.isNotEmpty) ...[
                    BackendNotice(
                      icon: Icons.error_outline_rounded,
                      title: 'Library error',
                      message: errorMessage,
                    ),
                    const SizedBox(height: 16),
                  ],
                  SectionHeader(
                    title: 'Album ca nhan',
                    action: 'Tao',
                    onTap: showCreateAlbumDialog,
                  ),
                  const SizedBox(height: 12),
                  if (albums.isEmpty)
                    const BackendNotice(
                      icon: Icons.album_rounded,
                      title: 'Chua co album',
                      message:
                          'Tao album ca nhan dau tien de gom nhac cua ban.',
                    )
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: albums
                          .map(
                            (album) => AlbumCard(
                              album: album,
                              onTap: () => openAlbum(album),
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 22),
                  SectionHeader(
                    title: 'Bai hat',
                    action: 'Upload',
                    onTap: showUploadSongDialog,
                  ),
                  const SizedBox(height: 12),
                  if (songs.isEmpty)
                    const BackendNotice(
                      icon: Icons.music_note_rounded,
                      title: 'Chua co bai hat',
                      message: 'Upload file audio de luu vao Supabase Storage.',
                    )
                  else
                    SongList(
                      songs: songs,
                      activeId: widget.controller.currentSong?.id,
                      activePlaying: widget.controller.isPlaying,
                      activeBusy: widget.controller.resolving,
                      onSongTap: (song) async {
                        await widget.controller.playSong(song, queue: songs);
                        if (mounted) {
                          widget.onOpenPlayer();
                        }
                      },
                      onActiveToggle: widget.controller.togglePlay,
                      onActiveOpen: widget.onOpenPlayer,
                      onSongAddToAlbum: showAddLibrarySongToAlbumDialog,
                    ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> showCreateAlbumDialog() async {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    PickedFileBytes? cover;

    try {
      final created = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          var busy = false;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: AppColors.card,
                title: const Text('Tao album ca nhan'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Ten album ca nhan',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: subtitleController,
                        decoration: const InputDecoration(
                          labelText: 'Ghi chu',
                        ),
                      ),
                      const SizedBox(height: 14),
                      AlbumCoverPicker(
                        cover: cover,
                        onTap: busy
                            ? null
                            : () async {
                                final picked = await pickFile(FileType.image);
                                if (picked == null) return;
                                setDialogState(() {
                                  cover = picked;
                                });
                              },
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
                            if (titleController.text.trim().isEmpty) {
                              showSnack('Nhap ten album.');
                              return;
                            }

                            setDialogState(() {
                              busy = true;
                            });

                            try {
                              await libraryGateway.createAlbum(
                                title: titleController.text,
                                subtitle: subtitleController.text,
                                coverBytes: cover?.bytes,
                                coverName: cover?.name,
                              );

                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop(true);
                              }
                            } catch (error) {
                              setDialogState(() {
                                busy = false;
                              });
                              showSnack('$error');
                            }
                          },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Tao'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (created == true) {
        await loadLibrary();
        showSnack('Da tao album.');
      }
    } finally {
      titleController.dispose();
      subtitleController.dispose();
    }
  }

  Future<void> showUploadSongDialog() async {
    final titleController = TextEditingController();
    final artistController = TextEditingController();
    PickedFileBytes? audio;
    PickedFileBytes? cover;

    try {
      final uploaded = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          var busy = false;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: AppColors.card,
                title: const Text('Upload bai hat'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilePickButton(
                        icon: Icons.audio_file_rounded,
                        label: audio?.name ?? 'Audio file',
                        onTap: busy
                            ? null
                            : () async {
                                final picked = await pickFile(FileType.audio);
                                if (picked == null) return;
                                setDialogState(() {
                                  audio = picked;
                                  if (titleController.text.trim().isEmpty) {
                                    titleController.text =
                                        file_path.basenameWithoutExtension(
                                      picked.name,
                                    );
                                  }
                                });
                              },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Ten bai hat',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: artistController,
                        decoration: const InputDecoration(
                          labelText: 'Nghe si',
                        ),
                      ),
                      const SizedBox(height: 12),
                      const BackendNotice(
                        icon: Icons.info_outline_rounded,
                        title: 'File upload luu rieng',
                        message:
                            'Album ca nhan chi them nhac YouTube tu trang Tim kiem hoac Trang chu.',
                      ),
                      const SizedBox(height: 14),
                      FilePickButton(
                        icon: Icons.image_rounded,
                        label: cover?.name ?? 'Cover',
                        onTap: busy
                            ? null
                            : () async {
                                final picked = await pickFile(FileType.image);
                                if (picked == null) return;
                                setDialogState(() {
                                  cover = picked;
                                });
                              },
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
                            if (audio == null) {
                              showSnack('Chon file audio.');
                              return;
                            }
                            if (titleController.text.trim().isEmpty) {
                              showSnack('Nhap ten bai hat.');
                              return;
                            }

                            setDialogState(() {
                              busy = true;
                            });

                            try {
                              await libraryGateway.uploadSong(
                                UploadedSongInput(
                                  title: titleController.text,
                                  artist: artistController.text,
                                  fileName: audio!.name,
                                  audioBytes: audio!.bytes,
                                  coverBytes: cover?.bytes,
                                  coverName: cover?.name,
                                ),
                              );

                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop(true);
                              }
                            } catch (error) {
                              setDialogState(() {
                                busy = false;
                              });
                              showSnack('$error');
                            }
                          },
                    icon: const Icon(Icons.cloud_upload_rounded),
                    label: const Text('Upload'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (uploaded == true) {
        await loadLibrary();
        showSnack('Da upload bai hat.');
      }
    } finally {
      titleController.dispose();
      artistController.dispose();
    }
  }

  Future<void> showAddLibrarySongToAlbumDialog(Song song) async {
    if (!song.isYoutube) {
      showSnack('Album chi them nhac YouTube.');
      return;
    }

    final titleController = TextEditingController();

    try {
      final message = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          var busy = false;
          var createNew = albums.isEmpty;
          var selectedAlbumId = albums.isEmpty ? '' : albums.first.id;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              final selectedAlbum = albumById(selectedAlbumId);

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
                      if (albums.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          initialValue: createNew ? '__new__' : selectedAlbumId,
                          decoration: const InputDecoration(
                            labelText: 'Album ca nhan',
                          ),
                          items: [
                            ...albums.map(
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
                          controller: titleController,
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
                                titleController.text.trim().isEmpty) {
                              showSnack('Nhap ten album.');
                              return;
                            }

                            setDialogState(() {
                              busy = true;
                            });

                            try {
                              final targetAlbum = createNew
                                  ? await libraryGateway.createAlbum(
                                      title: titleController.text,
                                    )
                                  : selectedAlbum;

                              if (targetAlbum == null) {
                                throw const LibraryGatewayException(
                                  'Chon album.',
                                );
                              }

                              await libraryGateway.addSongToAlbum(
                                songId: song.storedId,
                                albumId: targetAlbum.id,
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
        await loadLibrary();
        showSnack(message);
      }
    } finally {
      titleController.dispose();
    }
  }

  Future<void> openAlbum(Playlist album) async {
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
          child: FutureBuilder<Playlist>(
            future: libraryGateway.getAlbum(album.id),
            builder: (context, snapshot) {
              final loadedAlbum = snapshot.data ?? album;

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            loadedAlbum.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(22),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (snapshot.hasError)
                      BackendNotice(
                        icon: Icons.error_outline_rounded,
                        title: 'Album error',
                        message: '${snapshot.error}',
                      )
                    else if (loadedAlbum.songs.isEmpty)
                      const BackendNotice(
                        icon: Icons.music_note_rounded,
                        title: 'Album trong',
                        message:
                            'Tim bai hat roi bam nut them vao album ca nhan.',
                      )
                    else
                      Flexible(
                        child: SingleChildScrollView(
                          child: SongList(
                            songs: loadedAlbum.songs,
                            activeId: widget.controller.currentSong?.id,
                            activePlaying: widget.controller.isPlaying,
                            activeBusy: widget.controller.resolving,
                            onSongTap: (song) async {
                              await widget.controller.playSong(
                                song,
                                queue: loadedAlbum.songs,
                              );
                              openPlayerFromSheet();
                            },
                            onActiveToggle: widget.controller.togglePlay,
                            onActiveOpen: openPlayerFromSheet,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<PickedFileBytes?> pickFile(FileType type) async {
    final result = await FilePicker.pickFiles(
      type: type,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    final bytes = file.bytes;

    if (bytes == null || bytes.isEmpty) {
      showSnack('Khong doc duoc file.');
      return null;
    }

    return PickedFileBytes(name: file.name, bytes: bytes);
  }

  Playlist? albumById(String id) {
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

class PickedFileBytes {
  final String name;
  final Uint8List bytes;

  const PickedFileBytes({
    required this.name,
    required this.bytes,
  });
}

class LibraryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const LibraryActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class FilePickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const FilePickButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class AlbumCoverPicker extends StatelessWidget {
  final PickedFileBytes? cover;
  final VoidCallback? onTap;

  const AlbumCoverPicker({
    super.key,
    required this.cover,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedCover = cover;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox.square(
            dimension: 128,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: selectedCover == null
                  ? const CoverImage(
                      url: '',
                      size: 128,
                      radius: 18,
                    )
                  : Image.memory(
                      selectedCover.bytes,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        FilePickButton(
          icon: Icons.image_rounded,
          label: selectedCover?.name ?? 'Chon anh bia album',
          onTap: onTap,
        ),
      ],
    );
  }
}

class AlbumCard extends StatelessWidget {
  final Playlist album;
  final VoidCallback onTap;

  const AlbumCard({
    super.key,
    required this.album,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 138,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.card2,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CoverImage(
              url: album.coverUrl,
              size: 118,
              radius: 14,
            ),
            const SizedBox(height: 10),
            Text(
              album.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              album.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
