import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/song.dart';
import 'common_widgets.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final bool active;
  final bool playing;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onOpen;
  final VoidCallback? onAddToAlbum;
  final VoidCallback? onDelete;
  final bool favorite;
  final VoidCallback? onToggleFavorite;

  const SongTile({
    super.key,
    required this.song,
    required this.active,
    required this.onTap,
    this.playing = false,
    this.busy = false,
    this.onToggle,
    this.onOpen,
    this.onAddToAlbum,
    this.onDelete,
    this.favorite = false,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = song.album.trim().isEmpty
        ? song.artist
        : '${song.artist} • ${song.album}';

    return InkWell(
      onTap: active && onToggle != null ? onToggle : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color:
              active ? AppColors.muted.withValues(alpha: 0.28) : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: active ? null : Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            CoverImage(
              url: song.coverUrl,
              size: 52,
              radius: 13,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
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
            const SizedBox(width: 8),
            if (onToggleFavorite != null)
              _SongControlButton(
                tooltip: favorite ? 'Bỏ yêu thích' : 'Thêm vào yêu thích',
                icon: favorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: favorite ? AppColors.green2 : Colors.white,
                onPressed: onToggleFavorite,
              ),
            if (onAddToAlbum != null)
              _SongControlButton(
                tooltip: 'Thêm vào album',
                icon: Icons.playlist_add_rounded,
                onPressed: onAddToAlbum,
              ),
            if (onDelete != null)
              _SongControlButton(
                tooltip: 'Xóa file nhạc',
                icon: Icons.delete_outline_rounded,
                color: AppColors.pink,
                onPressed: onDelete,
              ),
            if (active)
              _ActiveSongControls(
                playing: playing,
                busy: busy,
                onToggle: onToggle,
                onOpen: onOpen,
              )
            else
              Text(
                song.durationText,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SongList extends StatelessWidget {
  final List<Song> songs;
  final String? activeId;
  final bool activePlaying;
  final bool activeBusy;
  final ValueChanged<Song> onSongTap;
  final VoidCallback? onActiveToggle;
  final VoidCallback? onActiveOpen;
  final ValueChanged<Song>? onSongAddToAlbum;
  final ValueChanged<Song>? onSongDelete;
  final bool Function(Song song)? isSongFavorite;
  final ValueChanged<Song>? onSongFavoriteToggle;

  const SongList({
    super.key,
    required this.songs,
    required this.activeId,
    required this.onSongTap,
    this.activePlaying = false,
    this.activeBusy = false,
    this.onActiveToggle,
    this.onActiveOpen,
    this.onSongAddToAlbum,
    this.onSongDelete,
    this.isSongFavorite,
    this.onSongFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return const BackendNotice(
        icon: Icons.music_off_rounded,
        title: 'Chưa có bài hát',
        message: 'Nhập tên bài hát hoặc nghệ sĩ để tìm và phát nhạc.',
      );
    }

    return Column(
      children: songs.map((song) {
        final active = song.id == activeId;
        final canAddToAlbum = onSongAddToAlbum != null;
        final canDelete = onSongDelete != null;
        final canFavorite = onSongFavoriteToggle != null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SongTile(
            song: song,
            active: active,
            playing: active && activePlaying,
            busy: active && activeBusy,
            onTap: () => onSongTap(song),
            onToggle: active ? onActiveToggle : null,
            onOpen: active ? onActiveOpen : null,
            onAddToAlbum: canAddToAlbum ? () => onSongAddToAlbum!(song) : null,
            onDelete: canDelete ? () => onSongDelete!(song) : null,
            favorite: isSongFavorite?.call(song) ?? false,
            onToggleFavorite:
                canFavorite ? () => onSongFavoriteToggle!(song) : null,
          ),
        );
      }).toList(),
    );
  }
}

class _ActiveSongControls extends StatelessWidget {
  final bool playing;
  final bool busy;
  final VoidCallback? onToggle;
  final VoidCallback? onOpen;

  const _ActiveSongControls({
    required this.playing,
    required this.busy,
    required this.onToggle,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _SongControlButton(
            tooltip: playing ? 'Pause' : 'Play',
            icon: busy
                ? Icons.hourglass_top_rounded
                : playing
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_fill_rounded,
            iconSize: 32,
            onPressed: busy ? null : onToggle,
          ),
          _SongControlButton(
            tooltip: 'Open',
            icon: Icons.expand_less_rounded,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

class _SongControlButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final double iconSize;
  final VoidCallback? onPressed;
  final Color? color;

  const _SongControlButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.iconSize = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 34,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: onPressed == null ? AppColors.muted : color ?? Colors.white,
          size: iconSize,
        ),
      ),
    );
  }
}
