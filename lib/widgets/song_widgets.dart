import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/song.dart';
import 'common_widgets.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final bool active;
  final VoidCallback onTap;

  const SongTile({
    super.key,
    required this.song,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active ? AppColors.green.withValues(alpha: 0.16) : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? AppColors.green : AppColors.line,
          ),
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
            const SizedBox(width: 8),
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
  final ValueChanged<Song> onSongTap;

  const SongList({
    super.key,
    required this.songs,
    required this.activeId,
    required this.onSongTap,
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
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SongTile(
            song: song,
            active: song.id == activeId,
            onTap: () => onSongTap(song),
          ),
        );
      }).toList(),
    );
  }
}
