import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/common_widgets.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TopBar(title: 'Thư viện'),
          const SizedBox(height: 14),
          const LibraryTile(
            color: AppColors.pink,
            icon: Icons.favorite_rounded,
            title: 'Bài hát đã thích',
            subtitle: 'Load from user backend',
          ),
          const SizedBox(height: 11),
          const LibraryTile(
            color: AppColors.green,
            icon: Icons.queue_music_rounded,
            title: 'Playlist cá nhân',
            subtitle: 'Load from user backend',
          ),
          const SizedBox(height: 11),
          const LibraryTile(
            color: AppColors.blue,
            icon: Icons.history_rounded,
            title: 'Nghe gần đây',
            subtitle: 'Load from user backend',
          ),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'Playlist',
            action: 'Backend',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          const PlaylistCard(),
        ],
      ),
    );
  }
}

class LibraryTile extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;

  const LibraryTile({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.16),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.muted,
          ),
        ],
      ),
    );
  }
}

class PlaylistCard extends StatelessWidget {
  const PlaylistCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card2,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: const Column(
        children: [
          AlbumBox(size: 130),
          SizedBox(height: 12),
          Text(
            'Playlist backend slot',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'User playlists will appear here',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}