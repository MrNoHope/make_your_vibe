import 'package:flutter/material.dart';

import '../../app_dependencies.dart';

class LibraryPlaylists extends StatelessWidget {
  const LibraryPlaylists({required this.c});

  final AppController c;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: () => _create(context),
          icon: const Icon(Icons.add),
          label: Text(c.tr('Tạo playlist', 'New playlist')),
        ),
        const SizedBox(height: 12),
        if (c.playlists.isEmpty)
          EmptyState(
            icon: Icons.queue_music,
            text: c.tr(
              'Tạo playlist đầu tiên để lưu các bài hát yêu thích.',
              'Create your first playlist to collect songs.',
            ),
          ),
        for (final playlist in c.playlists)
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.queue_music)),
              title: Text(playlist.name),
              subtitle: Text(
                '${playlist.songIds.length} ${c.tr('bài hát', 'songs')}',
              ),
              onTap: () => _open(context, playlist),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'share') {
                    c.shareText(
                      'Make Your Vibe Playlist: ${playlist.name}',
                    );
                  }
                  if (value == 'delete') {
                    c.deletePlaylist(playlist.id);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'share',
                    child: Text(c.tr('Chia sẻ', 'Share')),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(c.tr('Xóa', 'Delete')),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _create(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(c.tr('Tạo playlist', 'New playlist')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: c.tr('Tên playlist', 'Playlist name'),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              c.createPlaylist(controller.text);
              Navigator.pop(dialogContext);
            },
            child: Text(c.tr('Tạo', 'Create')),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _open(BuildContext context, PlaylistModel playlist) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, scrollController) {
          final songs = c.songsFor(playlist);
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(12),
            children: [
              ListTile(
                title: Text(
                  playlist.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  '${songs.length} ${c.tr('bài hát', 'songs')}',
                ),
                trailing: IconButton(
                  onPressed: songs.isEmpty
                      ? null
                      : () {
                          Navigator.pop(sheetContext);
                          c.playSong(songs.first, fromQueue: songs);
                        },
                  icon: const Icon(Icons.play_circle_fill),
                ),
              ),
              if (songs.isEmpty)
                EmptyState(
                  icon: Icons.music_note,
                  text: c.tr(
                    'Playlist này chưa có bài hát.',
                    'This playlist is empty.',
                  ),
                ),
              for (final song in songs)
                ListTile(
                  leading: SizedBox(
                    width: 48,
                    height: 48,
                    child: Cover(song: song, radius: 9),
                  ),
                  title: Text(song.title),
                  subtitle: Text(song.artist),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    c.playSong(song, fromQueue: songs);
                  },
                  trailing: IconButton(
                    tooltip: c.tr('Xóa khỏi playlist', 'Remove from playlist'),
                    onPressed: () => c.removeFromPlaylist(
                      playlist.id,
                      song.id,
                    ),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

