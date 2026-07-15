import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/models.dart';
import 'media_widgets.dart';

class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.c,
    required this.song,
    required this.queue,
    this.onEdit,
  });

  final AppController c;
  final Song song;
  final List<Song> queue;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final loading = c.loadingSongId == song.id;
    final selected = c.currentSong?.id == song.id && c.pendingSong == null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        minVerticalPadding: 8,
        contentPadding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
        leading: SizedBox(
          width: 54,
          height: 54,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Cover(song: song, radius: 11),
              if (loading)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.48),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              else if (selected)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.38),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Center(
                    child: Icon(
                      c.playing
                          ? Icons.equalizer_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            if (song.source == SongSource.local) ...[
              Icon(
                song.isPublic ? Icons.public : Icons.lock_outline,
                size: 14,
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        onTap: () => c.playSong(song, fromQueue: queue),
        trailing: PopupMenuButton<String>(
          tooltip: c.tr('Tùy chọn', 'More options'),
          onSelected: (value) {
            if (value == 'like') c.toggleLike(song);
            if (value.startsWith('pl:')) {
              c.addToPlaylist(value.substring(3), song);
            }
            if (value == 'share') {
              c.shareText('${song.title} - ${song.artist}');
            }
            if (value == 'edit') onEdit?.call();
            if (value == 'delete') c.deleteUpload(song);
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'like',
              child: Text(
                c.liked.contains(song.id)
                    ? c.tr('Bỏ thích', 'Unlike')
                    : c.tr('Yêu thích', 'Like'),
              ),
            ),
            for (final playlist in c.playlists)
              PopupMenuItem(
                value: 'pl:${playlist.id}',
                child: Text(
                  '${c.tr('Thêm vào', 'Add to')} ${playlist.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            PopupMenuItem(
              value: 'share',
              child: Text(c.tr('Chia sẻ', 'Share')),
            ),
            if (onEdit != null)
              PopupMenuItem(
                value: 'edit',
                child: Text(c.tr('Chỉnh sửa', 'Edit')),
              ),
            if (song.source == SongSource.local)
              PopupMenuItem(
                value: 'delete',
                child: Text(c.tr('Xóa bài đăng', 'Delete upload')),
              ),
          ],
        ),
      ),
    );
  }
}
