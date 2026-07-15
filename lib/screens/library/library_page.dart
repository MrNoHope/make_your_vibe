import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path/path.dart' as file_path;

import '../../controllers/vibe_controller.dart';
import '../../core/app_colors.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../../services/library_gateway.dart';
import '../../widgets/album_share_dialog.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/mini_player.dart';
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

  List<Song> get uploadedSongs => songs
      .where((song) => song.sourceType.trim() == 'upload')
      .toList(growable: false);

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
                title: 'Thư viện cá nhân',
                action: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Quét hoặc nhập mã share',
                      onPressed: showImportSharedAlbumDialog,
                      icon: const Icon(Icons.photo_camera_rounded),
                    ),
                    PopupMenuButton<_LibraryCreateAction>(
                      tooltip: 'Thêm vào thư viện',
                      enabled: configured,
                      color: AppColors.panel2,
                      icon: const Icon(Icons.add_rounded),
                      onSelected: (action) {
                        switch (action) {
                          case _LibraryCreateAction.album:
                            showCreateAlbumDialog();
                          case _LibraryCreateAction.upload:
                            showUploadSongDialog();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: _LibraryCreateAction.album,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.album_rounded),
                            title: Text('Tạo album cá nhân'),
                          ),
                        ),
                        PopupMenuItem(
                          value: _LibraryCreateAction.upload,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.upload_file_rounded),
                            title: Text('Upload nhạc'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _FavoriteSongsTile(
                count: widget.controller.favoriteSongs.length,
                coverUrl: widget.controller.favoriteSongs.isEmpty
                    ? ''
                    : widget.controller.favoriteSongs.first.coverUrl,
                onTap: openFavoriteSongs,
              ),
              const SizedBox(height: 22),
              const SectionHeader(title: 'Album yêu thích'),
              const SizedBox(height: 12),
              if (widget.controller.favoriteAlbums.isEmpty)
                const BackendNotice(
                  icon: Icons.favorite_border_rounded,
                  title: 'Chưa có album yêu thích',
                  message: 'Mở một album và nhấn trái tim để lưu tại đây.',
                )
              else
                SizedBox(
                  height: 184,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: widget.controller.favoriteAlbums.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final album = widget.controller.favoriteAlbums[index];
                      return AlbumCard(
                        album: album,
                        onTap: () => openFavoriteAlbum(album),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 22),
              if (!configured) ...[
                const BackendNotice(
                  icon: Icons.cloud_off_rounded,
                  title: 'Chưa cấu hình Firebase',
                  message: 'Thêm google-services.json và Firebase options.',
                ),
              ] else if (loading)
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
                _PersonalMusicTile(
                  count: uploadedSongs.length,
                  coverUrl:
                      uploadedSongs.isEmpty ? '' : uploadedSongs.first.coverUrl,
                  onTap: openPersonalMusic,
                ),
                const SizedBox(height: 22),
                const SectionHeader(title: 'Album cá nhân'),
                const SizedBox(height: 12),
                if (albums.isEmpty)
                  const BackendNotice(
                    icon: Icons.album_rounded,
                    title: 'Chưa có album',
                    message:
                        'Nhấn dấu + để tạo album, sau đó thêm bài yêu thích hoặc file upload.',
                  )
                else
                  SizedBox(
                    height: 184,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: albums.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final album = albums[index];
                        return AlbumCard(
                          album: album,
                          onTap: () => openAlbum(album),
                        );
                      },
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Playlist favoriteSongsPlaylist() {
    final favorites = widget.controller.favoriteSongs;

    return Playlist(
      id: 'favorite-songs',
      title: 'Bài hát yêu thích',
      subtitle: favorites.isEmpty
          ? 'Chưa có bài hát'
          : '${favorites.length} bài hát đã thích',
      coverUrl: favorites.isEmpty ? '' : favorites.first.coverUrl,
      songs: favorites,
    );
  }

  Future<void> openFavoriteSongs() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _AlbumDetailScreen(
          album: favoriteSongsPlaylist(),
          shared: false,
          favoriteEnabled: false,
          controller: widget.controller,
          onOpenPlayer: widget.onOpenPlayer,
          loadAlbum: () async => favoriteSongsPlaylist(),
          onShareAlbum: showSharePlaylistDialog,
          onShareImportedAlbum: showShareImportedAlbumDialog,
          onSongAddToAlbum: showAddLibrarySongToAlbumDialog,
        ),
      ),
    );
  }

  Future<void> openPersonalMusic() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _PersonalMusicScreen(
          initialSongs: uploadedSongs,
          controller: widget.controller,
          onOpenPlayer: widget.onOpenPlayer,
          onAddToAlbum: showAddLibrarySongToAlbumDialog,
          onDelete: deleteUploadedSong,
        ),
      ),
    );
    await loadLibrary();
  }

  Future<bool> deleteUploadedSong(Song song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Xóa file nhạc?'),
        content: Text(
          '"${song.title}" sẽ bị xóa khỏi Âm nhạc cá nhân và tất cả album cá nhân.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return false;
    }

    try {
      if (widget.controller.currentSong?.storedId == song.storedId) {
        await widget.controller.reset();
      }
      await libraryGateway.deleteUploadedSong(song);
      if (widget.controller.isFavoriteSong(song)) {
        await widget.controller.removeFavoriteSong(song);
      }
      await loadLibrary();
      showSnack('Đã xóa ${song.title}.');
      return true;
    } catch (error) {
      showSnack('$error');
      return false;
    }
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
                title: const Text('Tạo album cá nhân'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Tên album cá nhân',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: subtitleController,
                        decoration: const InputDecoration(
                          labelText: 'Ghi chú',
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
                    child: const Text('Hủy'),
                  ),
                  FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () async {
                            if (titleController.text.trim().isEmpty) {
                              showSnack('Nhập tên album.');
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
                    label: const Text('Tạo'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (created == true) {
        await loadLibrary();
        showSnack('Đã tạo album.');
      }
    } finally {
      titleController.dispose();
      subtitleController.dispose();
    }
  }

  Future<void> showUploadSongDialog() async {
    final titleController = TextEditingController();
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
                title: const Text('Upload bài hát'),
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
                          labelText: 'Tên bài hát',
                        ),
                      ),
                      const SizedBox(height: 10),
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
                    child: const Text('Hủy'),
                  ),
                  FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () async {
                            if (audio == null) {
                              showSnack('Chọn file audio.');
                              return;
                            }
                            if (titleController.text.trim().isEmpty) {
                              showSnack('Nhập tên bài hát.');
                              return;
                            }

                            setDialogState(() {
                              busy = true;
                            });

                            try {
                              await libraryGateway.uploadSong(
                                UploadedSongInput(
                                  title: titleController.text,
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
        showSnack('Đã upload bài hát.');
      }
    } finally {
      titleController.dispose();
    }
  }

  Future<void> showImportSharedAlbumDialog() async {
    final codeController = TextEditingController();

    try {
      final imported = await showDialog<Playlist>(
        context: context,
        builder: (dialogContext) {
          var busy = false;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: AppColors.card,
                title: Row(
                  children: [
                    const Expanded(child: Text('Nhập album share')),
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed:
                          busy ? null : () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Mã share',
                        hintText: 'Dán mã share hoặc mã mời bạn bè gửi',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: busy
                            ? null
                            : () async {
                                final scanned = await Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).push<String>(
                                  MaterialPageRoute(
                                    fullscreenDialog: true,
                                    builder: (_) =>
                                        const ShareCodeScannerPage(),
                                  ),
                                );

                                if (scanned == null ||
                                    scanned.trim().isEmpty ||
                                    !dialogContext.mounted) {
                                  return;
                                }

                                codeController.text =
                                    cleanShareCodePayload(scanned);
                              },
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        label: const Text('Quét mã'),
                      ),
                    ),
                  ],
                ),
                actions: [
                  FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () async {
                            if (codeController.text.trim().isEmpty) {
                              showSnack('Nhập mã share.');
                              return;
                            }

                            setDialogState(() {
                              busy = true;
                            });

                            try {
                              final album = await libraryGateway
                                  .importSharedAlbum(codeController.text);

                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop(album);
                              }
                            } catch (error) {
                              setDialogState(() {
                                busy = false;
                              });
                              showSnack('$error');
                            }
                          },
                    icon: busy
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_rounded),
                    label: const Text('Thêm'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (imported != null) {
        showSnack('Đã mở album ${imported.title}.');
        await openAlbum(imported, shared: true);
      }
    } finally {
      codeController.dispose();
    }
  }

  Future<void> showAddLibrarySongToAlbumDialog(Song song) async {
    final titleController = TextEditingController();

    try {
      final message = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          var busy = false;
          var createNew = albums.isEmpty;
          final selectedAlbumIds = <String>{};

          return StatefulBuilder(
            builder: (context, setDialogState) {
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
                      if (albums.isNotEmpty) ...[
                        const Text(
                          'Chọn một hoặc nhiều album',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: ListView(
                            shrinkWrap: true,
                            children: albums
                                .map(
                                  (album) => CheckboxListTile(
                                    value: selectedAlbumIds.contains(album.id),
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    title: Text(
                                      album.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onChanged: busy
                                        ? null
                                        : (selected) {
                                            setDialogState(() {
                                              if (selected == true) {
                                                selectedAlbumIds.add(album.id);
                                              } else {
                                                selectedAlbumIds
                                                    .remove(album.id);
                                              }
                                            });
                                          },
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ),
                        CheckboxListTile(
                          value: createNew,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: const Text('Tạo thêm album mới'),
                          onChanged: busy
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    createNew = value == true;
                                  });
                                },
                        ),
                      ],
                      if (createNew)
                        TextField(
                          controller: titleController,
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
                            final newTitle = titleController.text.trim();
                            if (createNew && newTitle.isEmpty) {
                              showSnack('Nhập tên album.');
                              return;
                            }
                            if (selectedAlbumIds.isEmpty && !createNew) {
                              showSnack('Chọn ít nhất một album.');
                              return;
                            }

                            setDialogState(() {
                              busy = true;
                            });

                            try {
                              final targetAlbums = albums
                                  .where(
                                    (album) =>
                                        selectedAlbumIds.contains(album.id),
                                  )
                                  .toList();
                              if (createNew) {
                                targetAlbums.add(
                                  await libraryGateway.createAlbum(
                                    title: newTitle,
                                  ),
                                );
                              }

                              for (final targetAlbum in targetAlbums) {
                                await libraryGateway.saveSongToAlbum(
                                  song: song,
                                  albumId: targetAlbum.id,
                                  albumTitle: targetAlbum.title,
                                );
                              }

                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop(
                                  targetAlbums.length == 1
                                      ? 'Đã thêm vào ${targetAlbums.first.title}.'
                                      : 'Đã thêm vào ${targetAlbums.length} album cá nhân.',
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
        await loadLibrary();
        showSnack(message);
      }
    } finally {
      titleController.dispose();
    }
  }

  Future<void> showShareAlbumDialog(Playlist album) async {
    try {
      showSnack('Đang tạo mã share...');
      final code = await libraryGateway.shareAlbum(album.id);

      if (!mounted) {
        return;
      }

      await showShareCodeDialog(
        album: album,
        code: code,
        title: 'Mã share album',
        codeLabel: 'Mã share',
        savedMessage: 'Đã lưu ảnh mã share.',
        shareText: 'Nghe album "${album.title}" trên '
            'Make Your Vibe.\nMã share: $code',
        subject: 'Make Your Vibe - ${album.title}',
        onStopSharing: () => libraryGateway.stopSharingAlbum(code),
        stopMessage: 'Đã ngừng chia sẻ. Người đã lưu vẫn nghe được.',
      );
    } catch (error) {
      showSnack('$error');
    }
  }

  Future<void> showSharePlaylistDialog(Playlist album) async {
    try {
      showSnack('Đang tạo mã share...');
      final code = await libraryGateway.sharePlaylist(album);

      if (!mounted) {
        return;
      }

      await showShareCodeDialog(
        album: album,
        code: code,
        title: 'Mã share album',
        codeLabel: 'Mã share',
        savedMessage: 'Đã lưu ảnh mã share.',
        shareText: 'Nghe album "${album.title}" trên '
            'Make Your Vibe.\nMã share: $code',
        subject: 'Make Your Vibe - ${album.title}',
        onStopSharing: () => libraryGateway.stopSharingAlbum(code),
        stopMessage: 'Đã ngừng chia sẻ. Người đã lưu vẫn nghe được.',
      );
    } catch (error) {
      showSnack('$error');
    }
  }

  Future<void> showShareImportedAlbumDialog(Playlist album) async {
    try {
      showSnack('Đang tạo mã mời...');
      final code = await libraryGateway.createSharedAlbumInvite(album.shareId);

      if (!mounted) {
        return;
      }

      await showShareCodeDialog(
        album: album,
        code: code,
        title: 'Mã mời album',
        codeLabel: 'Mã mời',
        savedMessage: 'Đã lưu ảnh mã mời.',
        shareText: 'Nghe album "${album.title}" trên '
            'Make Your Vibe.\nMã mời: $code',
        subject: 'Make Your Vibe - ${album.title}',
        note: 'Mã mời chỉ dùng được khi album gốc còn đang chia sẻ.',
      );
    } catch (error) {
      showSnack('$error');
    }
  }

  Future<void> showShareCodeDialog({
    required Playlist album,
    required String code,
    required String title,
    required String codeLabel,
    required String savedMessage,
    required String shareText,
    required String subject,
    String? note,
    Future<void> Function()? onStopSharing,
    String? stopMessage,
  }) async {
    await showAlbumShareDialog(
      context: context,
      album: album,
      code: code,
      title: title,
      codeLabel: codeLabel,
      savedMessage: savedMessage,
      shareText: shareText,
      subject: subject,
      note: note,
      onStopSharing: onStopSharing,
      stopMessage: stopMessage,
    );
  }

  Future<void> openFavoriteAlbum(Playlist album) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _AlbumDetailScreen(
          album: album,
          shared: album.isShared,
          controller: widget.controller,
          onOpenPlayer: widget.onOpenPlayer,
          loadAlbum: () async => album,
          onShareAlbum: showSharePlaylistDialog,
          onShareImportedAlbum: showShareImportedAlbumDialog,
          onSongAddToAlbum: showAddLibrarySongToAlbumDialog,
        ),
      ),
    );
  }

  Future<void> openAlbum(Playlist album, {bool shared = false}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _AlbumDetailScreen(
          album: album,
          shared: shared,
          editable: !shared,
          controller: widget.controller,
          onOpenPlayer: widget.onOpenPlayer,
          loadAlbum: () => shared
              ? libraryGateway.getImportedSharedAlbum(album.shareId)
              : libraryGateway.getAlbum(album.id),
          onShareAlbum: showShareAlbumDialog,
          onShareImportedAlbum: showShareImportedAlbumDialog,
          onSongAddToAlbum: showAddLibrarySongToAlbumDialog,
        ),
      ),
    );
    if (!shared) {
      await loadLibrary();
    }
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

enum _LibraryCreateAction { album, upload }

enum _AlbumMenuAction { share }

enum _AlbumSongAction { play, addToAlbum, removeFromAlbum, openPlayer }

class _FavoriteSongsTile extends StatelessWidget {
  final int count;
  final String coverUrl;
  final VoidCallback onTap;

  const _FavoriteSongsTile({
    required this.count,
    required this.coverUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = count == 0
        ? 'Danh sách phát • Chưa có bài hát'
        : 'Danh sách phát • $count bài hát';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              _FavoriteSongsCover(coverUrl: coverUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bài hát yêu thích',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.soft,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.soft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteSongsCover extends StatelessWidget {
  final String coverUrl;

  const _FavoriteSongsCover({required this.coverUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 64,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (coverUrl.trim().isNotEmpty)
            CoverImage(
              url: coverUrl,
              size: 64,
              radius: 8,
            )
          else
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4B32F4),
                    Color(0xFF7A5CFF),
                    Color(0xFF9FFFD2),
                  ],
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.black.withValues(alpha: 0.08),
            ),
          ),
          const Center(
            child: Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalMusicTile extends StatelessWidget {
  final int count;
  final String coverUrl;
  final VoidCallback onTap;

  const _PersonalMusicTile({
    required this.count,
    required this.coverUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = count == 0
        ? 'File tải lên • Chưa có bài hát'
        : 'File tải lên • $count bài hát';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 64,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (coverUrl.trim().isNotEmpty)
                      CoverImage(url: coverUrl, size: 64, radius: 8)
                    else
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF0D5C63),
                              Color(0xFF28A17A),
                              Color(0xFF9BE564),
                            ],
                          ),
                        ),
                      ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black.withValues(alpha: 0.1),
                      ),
                    ),
                    const Center(
                      child: Icon(
                        Icons.audio_file_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Âm nhạc cá nhân',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.soft,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.soft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonalMusicScreen extends StatefulWidget {
  final List<Song> initialSongs;
  final VibeController controller;
  final VoidCallback onOpenPlayer;
  final ValueChanged<Song> onAddToAlbum;
  final Future<bool> Function(Song song) onDelete;

  const _PersonalMusicScreen({
    required this.initialSongs,
    required this.controller,
    required this.onOpenPlayer,
    required this.onAddToAlbum,
    required this.onDelete,
  });

  @override
  State<_PersonalMusicScreen> createState() => _PersonalMusicScreenState();
}

class _PersonalMusicScreenState extends State<_PersonalMusicScreen> {
  late List<Song> songs = List.of(widget.initialSongs);

  Future<void> _deleteSong(Song song) async {
    final deleted = await widget.onDelete(song);
    if (!deleted || !mounted) {
      return;
    }

    setState(() {
      songs = songs
          .where((item) => item.storedId != song.storedId)
          .toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Quay lại',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Âm nhạc cá nhân',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Các file nhạc bạn đã tải lên.',
                    style: TextStyle(
                      color: AppColors.soft,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (songs.isEmpty)
                    const BackendNotice(
                      icon: Icons.audio_file_rounded,
                      title: 'Chưa có file nhạc',
                      message: 'Nhấn dấu + trong Thư viện để upload bài hát.',
                    )
                  else
                    AnimatedBuilder(
                      animation: widget.controller,
                      builder: (context, _) => SongList(
                        songs: songs,
                        activeId: widget.controller.currentSong?.id,
                        activePlaying: widget.controller.isPlaying,
                        activeBusy: widget.controller.resolving,
                        onSongTap: (song) async {
                          await widget.controller.playSong(
                            song,
                            queue: songs,
                            context: const PlayContextInfo(
                              type: PlayOriginType.library,
                              title: 'Âm nhạc cá nhân',
                            ),
                          );
                          if (mounted) {
                            widget.onOpenPlayer();
                          }
                        },
                        onActiveToggle: widget.controller.togglePlay,
                        onActiveOpen: widget.onOpenPlayer,
                        onSongAddToAlbum: widget.onAddToAlbum,
                        onSongDelete: _deleteSong,
                        isSongFavorite: widget.controller.isFavoriteSong,
                        onSongFavoriteToggle:
                            widget.controller.toggleFavoriteSong,
                      ),
                    ),
                ],
              ),
            ),
            MiniPlayerBar(
              controller: widget.controller,
              onTap: widget.onOpenPlayer,
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumDetailScreen extends StatefulWidget {
  final Playlist album;
  final bool shared;
  final bool editable;
  final bool favoriteEnabled;
  final VibeController controller;
  final VoidCallback onOpenPlayer;
  final Future<Playlist> Function() loadAlbum;
  final Future<void> Function(Playlist album) onShareAlbum;
  final Future<void> Function(Playlist album) onShareImportedAlbum;
  final ValueChanged<Song> onSongAddToAlbum;

  const _AlbumDetailScreen({
    required this.album,
    required this.shared,
    this.editable = false,
    this.favoriteEnabled = true,
    required this.controller,
    required this.onOpenPlayer,
    required this.loadAlbum,
    required this.onShareAlbum,
    required this.onShareImportedAlbum,
    required this.onSongAddToAlbum,
  });

  @override
  State<_AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<_AlbumDetailScreen> {
  late Future<Playlist> _albumFuture;

  @override
  void initState() {
    super.initState();
    _albumFuture = widget.loadAlbum();
  }

  void _playAlbum(Playlist album) {
    if (album.songs.isEmpty) {
      return;
    }

    if (_isCurrentAlbum(album)) {
      widget.controller.togglePlay();
      return;
    }

    widget.controller.playSong(
      album.songs.first,
      queue: album.songs,
      context: PlayContextInfo(
        type: PlayOriginType.album,
        title: album.title,
      ),
    );
  }

  void _playSong(Playlist album, Song song) {
    widget.controller.playSong(
      song,
      queue: album.songs,
      context: PlayContextInfo(
        type: PlayOriginType.album,
        title: album.title,
      ),
    );
  }

  void _shareAlbum(Playlist album) {
    if (widget.shared) {
      if (album.canShare) {
        widget.onShareImportedAlbum(album);
      }
      return;
    }

    widget.onShareAlbum(album);
  }

  Future<void> _removeSongFromAlbum(Song song) async {
    try {
      await libraryGateway.removeSongFromAlbum(
        song: song,
        albumId: widget.album.id,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _albumFuture = widget.loadAlbum();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xóa ${song.title} khỏi album.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  bool _isCurrentAlbum(Playlist album) {
    final currentId = widget.controller.currentSong?.id;
    if (currentId == null) {
      return false;
    }

    return album.songs.any((song) => song.id == currentId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<Playlist>(
                future: _albumFuture,
                builder: (context, snapshot) {
                  final album = snapshot.data ?? widget.album;
                  final loading =
                      snapshot.connectionState == ConnectionState.waiting;

                  return AnimatedBuilder(
                    animation: widget.controller,
                    builder: (context, _) {
                      return _AlbumDetailContent(
                        album: album,
                        shared: widget.shared,
                        editable: widget.editable,
                        loading: loading,
                        error: snapshot.error,
                        controller: widget.controller,
                        onBack: () => Navigator.of(context).maybePop(),
                        favorite: widget.favoriteEnabled &&
                            widget.controller.isFavoriteAlbum(album),
                        onFavoriteToggle: widget.favoriteEnabled
                            ? () => widget.controller.toggleFavoriteAlbum(album)
                            : null,
                        onShare: () => _shareAlbum(album),
                        onPlayAlbum: loading || snapshot.hasError
                            ? null
                            : () => _playAlbum(album),
                        onSongTap: (song) => _playSong(album, song),
                        onSongAddToAlbum: widget.onSongAddToAlbum,
                        onSongRemove:
                            widget.editable ? _removeSongFromAlbum : null,
                        onOpenPlayer: widget.onOpenPlayer,
                      );
                    },
                  );
                },
              ),
            ),
            MiniPlayerBar(
              controller: widget.controller,
              onTap: widget.onOpenPlayer,
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumDetailContent extends StatelessWidget {
  final Playlist album;
  final bool shared;
  final bool editable;
  final bool loading;
  final Object? error;
  final VibeController controller;
  final VoidCallback onBack;
  final bool favorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onShare;
  final VoidCallback? onPlayAlbum;
  final ValueChanged<Song> onSongTap;
  final ValueChanged<Song> onSongAddToAlbum;
  final ValueChanged<Song>? onSongRemove;
  final VoidCallback onOpenPlayer;

  const _AlbumDetailContent({
    required this.album,
    required this.shared,
    required this.editable,
    required this.loading,
    required this.error,
    required this.controller,
    required this.onBack,
    required this.favorite,
    required this.onFavoriteToggle,
    required this.onShare,
    required this.onPlayAlbum,
    required this.onSongTap,
    required this.onSongAddToAlbum,
    required this.onSongRemove,
    required this.onOpenPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    final activeInAlbum = _albumContainsCurrentSong(album, controller);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _AlbumTopBar(
          album: album,
          shared: shared,
          favorite: favorite,
          onBack: onBack,
          onFavoriteToggle: onFavoriteToggle,
          onShare: onShare,
        ),
        const SizedBox(height: 4),
        _AlbumHeroCover(album: album),
        const SizedBox(height: 18),
        _AlbumTitleBlock(album: album),
        const SizedBox(height: 18),
        _AlbumControlRow(
          album: album,
          controller: controller,
          activeInAlbum: activeInAlbum,
          onPlayAlbum: onPlayAlbum,
        ),
        const SizedBox(height: 18),
        if (shared && !loading && !album.canShare) ...[
          const BackendNotice(
            icon: Icons.link_off_rounded,
            title: 'Album đã ngừng chia sẻ',
            message:
                'Bạn vẫn nghe được bản đã lưu, nhưng không thể gửi mã mời mới.',
          ),
          const SizedBox(height: 14),
        ],
        if (loading)
          const Padding(
            padding: EdgeInsets.only(top: 28),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (hasError)
          BackendNotice(
            icon: Icons.error_outline_rounded,
            title: 'Album lỗi',
            message: '$error',
          )
        else if (album.songs.isEmpty)
          const BackendNotice(
            icon: Icons.music_note_rounded,
            title: 'Album trống',
            message: 'Tìm bài hát rồi thêm vào album cá nhân.',
          )
        else
          ...album.songs.map(
            (song) => _AlbumSongRow(
              song: song,
              active: song.id == controller.currentSong?.id,
              playing: controller.isPlaying,
              busy:
                  controller.resolving && song.id == controller.currentSong?.id,
              favorite: controller.isFavoriteSong(song),
              onTap: () => onSongTap(song),
              onFavoriteToggle: () => controller.toggleFavoriteSong(song),
              onAddToAlbum: () => onSongAddToAlbum(song),
              canRemove: editable && onSongRemove != null,
              onRemove: () => onSongRemove?.call(song),
              onOpenPlayer: onOpenPlayer,
            ),
          ),
      ],
    );
  }
}

class _AlbumTopBar extends StatelessWidget {
  final Playlist album;
  final bool shared;
  final bool favorite;
  final VoidCallback onBack;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onShare;

  const _AlbumTopBar({
    required this.album,
    required this.shared,
    required this.favorite,
    required this.onBack,
    required this.onFavoriteToggle,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final canShare = !shared || album.canShare;

    return Row(
      children: [
        IconButton(
          tooltip: 'Quay lại',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const Spacer(),
        if (onFavoriteToggle != null)
          IconButton(
            tooltip: favorite ? 'Bỏ yêu thích album' : 'Yêu thích album',
            onPressed: onFavoriteToggle,
            icon: Icon(
              favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: favorite ? AppColors.green : null,
            ),
          ),
        PopupMenuButton<_AlbumMenuAction>(
          tooltip: 'Tùy chọn album',
          color: AppColors.panel2,
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (_) => onShare?.call(),
          itemBuilder: (context) {
            if (!canShare) {
              return const [
                PopupMenuItem<_AlbumMenuAction>(
                  enabled: false,
                  child: Text(
                    'Đã ngừng chia sẻ',
                    style: TextStyle(color: AppColors.soft),
                  ),
                ),
              ];
            }

            return [
              PopupMenuItem<_AlbumMenuAction>(
                value: _AlbumMenuAction.share,
                child: Row(
                  children: [
                    const Icon(
                      Icons.ios_share_rounded,
                      color: AppColors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      shared ? 'Gửi mã mời' : 'Chia sẻ album',
                      style: const TextStyle(color: AppColors.text),
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      ],
    );
  }
}

class _AlbumHeroCover extends StatelessWidget {
  final Playlist album;

  const _AlbumHeroCover({required this.album});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = (constraints.maxWidth * 0.64).clamp(184.0, 236.0);

        return Center(
          child: CoverImage(
            url: _albumCoverUrl(album),
            size: size.toDouble(),
            radius: 4,
          ),
        );
      },
    );
  }
}

class _AlbumTitleBlock extends StatelessWidget {
  final Playlist album;

  const _AlbumTitleBlock({required this.album});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _albumTitle(album),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 10),
        _AlbumCreatorLine(album: album),
        const SizedBox(height: 12),
        Text(
          'Album • ${album.songs.length} bài hát',
          style: const TextStyle(
            color: AppColors.soft,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AlbumCreatorLine extends StatelessWidget {
  final Playlist album;

  const _AlbumCreatorLine({required this.album});

  @override
  Widget build(BuildContext context) {
    final covers = album.songs
        .map((song) => song.coverUrl.trim())
        .where((url) => url.isNotEmpty)
        .take(2)
        .toList();

    return Row(
      children: [
        SizedBox(
          width: covers.length > 1 ? 32 : 20,
          height: 20,
          child: Stack(
            children: [
              if (covers.isEmpty)
                const CircleAvatar(
                  radius: 10,
                  backgroundColor: AppColors.panel2,
                  child: Icon(
                    Icons.music_note_rounded,
                    color: AppColors.green,
                    size: 12,
                  ),
                )
              else
                for (var index = 0; index < covers.length; index += 1)
                  Positioned(
                    left: index * 12,
                    child: ClipOval(
                      child: CoverImage(
                        url: covers[index],
                        size: 20,
                        radius: 99,
                      ),
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _albumSubtitle(album),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _AlbumControlRow extends StatelessWidget {
  final Playlist album;
  final VibeController controller;
  final bool activeInAlbum;
  final VoidCallback? onPlayAlbum;

  const _AlbumControlRow({
    required this.album,
    required this.controller,
    required this.activeInAlbum,
    required this.onPlayAlbum,
  });

  @override
  Widget build(BuildContext context) {
    final canPlay = album.songs.isNotEmpty && onPlayAlbum != null;

    return Row(
      children: [
        CoverImage(
          url: _albumCoverUrl(album),
          size: 38,
          radius: 4,
        ),
        const SizedBox(width: 14),
        _AlbumSmallIcon(
          tooltip: album.isShared ? 'Đã lưu album chia sẻ' : 'Album cá nhân',
          icon: album.isShared ? Icons.people_alt_rounded : Icons.check_rounded,
        ),
        const Spacer(),
        Tooltip(
          message: 'Phát xen kẽ',
          child: IconButton(
            onPressed: controller.toggleShuffle,
            icon: Icon(
              Icons.shuffle_rounded,
              color:
                  controller.shuffleEnabled ? AppColors.green : AppColors.soft,
              size: 26,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _AlbumPlayButton(
          enabled: canPlay,
          activeInAlbum: activeInAlbum,
          playing: controller.isPlaying,
          busy: controller.resolving && activeInAlbum,
          onPressed: onPlayAlbum,
        ),
      ],
    );
  }
}

class _AlbumSmallIcon extends StatelessWidget {
  final String tooltip;
  final IconData icon;

  const _AlbumSmallIcon({
    required this.tooltip,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: AppColors.green,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.black,
          size: 15,
        ),
      ),
    );
  }
}

class _AlbumPlayButton extends StatelessWidget {
  final bool enabled;
  final bool activeInAlbum;
  final bool playing;
  final bool busy;
  final VoidCallback? onPressed;

  const _AlbumPlayButton({
    required this.enabled,
    required this.activeInAlbum,
    required this.playing,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final icon = busy
        ? Icons.hourglass_top_rounded
        : activeInAlbum && playing
            ? Icons.pause_rounded
            : Icons.play_arrow_rounded;

    return Tooltip(
      message: activeInAlbum && playing ? 'Tạm dừng' : 'Phát album',
      child: InkWell(
        onTap: enabled && !busy ? onPressed : null,
        customBorder: const CircleBorder(),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: enabled ? AppColors.green : AppColors.muted,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.black,
            size: 34,
          ),
        ),
      ),
    );
  }
}

class _AlbumSongRow extends StatelessWidget {
  final Song song;
  final bool active;
  final bool playing;
  final bool busy;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onAddToAlbum;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onOpenPlayer;

  const _AlbumSongRow({
    required this.song,
    required this.active,
    required this.playing,
    required this.busy,
    required this.favorite,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onAddToAlbum,
    required this.canRemove,
    required this.onRemove,
    required this.onOpenPlayer,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active ? AppColors.green : AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        active && playing
                            ? Icons.equalizer_rounded
                            : Icons.check_circle_rounded,
                        color: AppColors.green,
                        size: 12,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          song.artist.trim().isEmpty
                              ? 'Make Your Vibe'
                              : song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.soft,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: favorite ? 'Bỏ yêu thích' : 'Thêm vào yêu thích',
              onPressed: onFavoriteToggle,
              icon: Icon(
                favorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: favorite ? AppColors.green2 : AppColors.soft,
              ),
            ),
            if (busy)
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              PopupMenuButton<_AlbumSongAction>(
                tooltip: 'Tùy chọn bài hát',
                color: AppColors.panel2,
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.soft,
                ),
                onSelected: (action) {
                  switch (action) {
                    case _AlbumSongAction.play:
                      onTap();
                      break;
                    case _AlbumSongAction.addToAlbum:
                      onAddToAlbum();
                      break;
                    case _AlbumSongAction.removeFromAlbum:
                      onRemove();
                      break;
                    case _AlbumSongAction.openPlayer:
                      onOpenPlayer();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<_AlbumSongAction>(
                    value: _AlbumSongAction.play,
                    child: Text(
                      'Phát bài này',
                      style: TextStyle(color: AppColors.text),
                    ),
                  ),
                  const PopupMenuItem<_AlbumSongAction>(
                    value: _AlbumSongAction.addToAlbum,
                    child: Text(
                      'Thêm vào album cá nhân',
                      style: TextStyle(color: AppColors.text),
                    ),
                  ),
                  if (canRemove)
                    const PopupMenuItem<_AlbumSongAction>(
                      value: _AlbumSongAction.removeFromAlbum,
                      child: Text(
                        'Xóa khỏi album này',
                        style: TextStyle(color: AppColors.pink),
                      ),
                    ),
                  const PopupMenuItem<_AlbumSongAction>(
                    value: _AlbumSongAction.openPlayer,
                    child: Text(
                      'Mở trình phát',
                      style: TextStyle(color: AppColors.text),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

String _albumTitle(Playlist album) {
  final title = album.title.trim();
  return title.isEmpty ? 'Album' : title;
}

String _albumSubtitle(Playlist album) {
  final subtitle = album.subtitle.trim();
  if (subtitle.isNotEmpty) {
    return subtitle;
  }

  final artists = <String>{};
  for (final song in album.songs) {
    final artist = song.artist.trim();
    if (artist.isNotEmpty) {
      artists.add(artist);
    }
  }

  if (artists.isEmpty) {
    return 'Make Your Vibe';
  }

  return artists.take(3).join(', ');
}

String _albumCoverUrl(Playlist album) {
  final coverUrl = album.coverUrl.trim();
  if (coverUrl.isNotEmpty) {
    return coverUrl;
  }

  const personalAlbumCovers = <String, String>{
    'fan bray': 'https://i.ytimg.com/vi/tcV47TTTU_U/hqdefault.jpg',
    'diss nyc': 'https://i.ytimg.com/vi/mdd9FENKmDk/hqdefault.jpg',
    'ếch và báo': 'https://i.ytimg.com/vi/Humu5wAysrc/hqdefault.jpg',
    'socola kẹo mút': 'https://i.ytimg.com/vi/UGICe53lQjQ/hqdefault.jpg',
  };
  final namedCover = personalAlbumCovers[album.title.trim().toLowerCase()];
  if (namedCover != null) {
    return namedCover;
  }

  for (final song in album.songs) {
    final songCover = song.coverUrl.trim();
    if (songCover.isNotEmpty) {
      return songCover;
    }
  }

  return '';
}

bool _albumContainsCurrentSong(Playlist album, VibeController controller) {
  final currentId = controller.currentSong?.id;
  if (currentId == null) {
    return false;
  }

  return album.songs.any((song) => song.id == currentId);
}

String cleanShareCodePayload(String payload) {
  final raw = payload.trim();
  if (raw.isEmpty) {
    return '';
  }

  final uri = Uri.tryParse(raw);
  if (uri != null) {
    final code = uri.queryParameters['code'];
    if (code != null && code.trim().isNotEmpty) {
      return code.trim();
    }

    if (uri.scheme == 'make-your-vibe' &&
        uri.host == 'share' &&
        uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first.trim();
    }
  }

  return raw;
}

class ShareCodeScannerPage extends StatefulWidget {
  const ShareCodeScannerPage({super.key});

  @override
  State<ShareCodeScannerPage> createState() => _ShareCodeScannerPageState();
}

class _ShareCodeScannerPageState extends State<ShareCodeScannerPage> {
  late final MobileScannerController scannerController;
  bool handled = false;

  @override
  void initState() {
    super.initState();
    scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  void handleScan(BarcodeCapture capture) {
    if (handled) {
      return;
    }

    for (final barcode in capture.barcodes) {
      final code = cleanShareCodePayload(barcode.rawValue ?? '');
      if (code.isEmpty) {
        continue;
      }

      handled = true;
      Navigator.of(context).pop(code);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Quét mã album'),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: scannerController,
            onDetect: handleScan,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Không mở được camera: ${error.errorCode.name}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          ),
          Center(
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.green, width: 3),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 34,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Đưa QR trên thẻ share vào khung để nhập album.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
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
          label: selectedCover?.name ?? 'Chọn ảnh bìa album',
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
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 132,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox.square(
              dimension: 132,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CoverImage(
                    url: _albumCoverUrl(album),
                    size: double.infinity,
                    radius: 8,
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: CircleAvatar(
                      radius: 17,
                      backgroundColor: AppColors.green.withValues(alpha: 0.92),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 22,
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
