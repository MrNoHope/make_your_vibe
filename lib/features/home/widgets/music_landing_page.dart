import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/controllers/app_locale_controller.dart';
import '../../player/widgets/mini_player_bar.dart';
import 'home_header.dart';

class MusicLandingPage extends StatelessWidget {
  const MusicLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.watch<AppLocaleController>().currentLanguage;
    final isVietnamese = language == AppLanguage.vi;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HomeHeader(),
                  const SizedBox(height: AppSpacing.lg),
                  const _MusicFilterChips(),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    isVietnamese ? 'Nghe nhanh' : 'Quick Picks',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _QuickMusicGrid(),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    isVietnamese ? 'Nhảy vào nghe tiếp' : 'Jump Back In',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _HorizontalSongList(),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    isVietnamese ? 'Gợi ý cho bạn' : 'Made for You',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _RecommendedSongList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const MiniPlayerBar(),
        ],
      ),
    );
  }
}

class _MusicFilterChips extends StatelessWidget {
  const _MusicFilterChips();

  @override
  Widget build(BuildContext context) {
    final language = context.watch<AppLocaleController>().currentLanguage;
    final isVietnamese = language == AppLanguage.vi;

    final filters = isVietnamese
        ? ['Tất cả', 'Nhạc', 'Playlist', 'Nghệ sĩ']
        : ['All', 'Music', 'Playlists', 'Artists'];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final active = index == 0;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              filters[index],
              style: TextStyle(
                color: active ? Colors.black : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickMusicGrid extends StatelessWidget {
  const _QuickMusicGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.7,
      children: const [
        _MusicShortcutTile(
          icon: Icons.favorite_rounded,
          title: 'Liked Songs',
          color: Color(0xFF5E4AE3),
        ),
        _MusicShortcutTile(
          icon: Icons.queue_music_rounded,
          title: 'Daily Mix',
          color: Color(0xFF1DB954),
        ),
        _MusicShortcutTile(
          icon: Icons.album_rounded,
          title: 'Top Hits',
          color: Color(0xFF2C5364),
        ),
        _MusicShortcutTile(
          icon: Icons.nights_stay_rounded,
          title: 'Late Night',
          color: Color(0xFF734B6D),
        ),
      ],
    );
  }
}

class _MusicShortcutTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _MusicShortcutTile({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.28),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            Container(
              width: 54,
              height: double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(14),
                ),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalSongList extends StatelessWidget {
  const _HorizontalSongList();

  @override
  Widget build(BuildContext context) {
    final songs = const [
      _SongPreviewData(
        title: 'Em của ngày hôm qua',
        artist: 'Sơn Tùng M-TP',
        icon: Icons.music_note_rounded,
        color: Color(0xFF1DB954),
      ),
      _SongPreviewData(
        title: 'Lofi Study',
        artist: 'Make Your Vibe',
        icon: Icons.headphones_rounded,
        color: Color(0xFF4B6CB7),
      ),
      _SongPreviewData(
        title: 'Chill Night',
        artist: 'Daily Mood',
        icon: Icons.nightlight_round,
        color: Color(0xFF734B6D),
      ),
    ];

    return SizedBox(
      height: 178,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: songs.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final song = songs[index];

          return _SongCard(song: song);
        },
      ),
    );
  }
}

class _RecommendedSongList extends StatelessWidget {
  const _RecommendedSongList();

  @override
  Widget build(BuildContext context) {
    final songs = const [
      _SongPreviewData(
        title: 'Focus Flow',
        artist: 'Instrumental Mix',
        icon: Icons.bolt_rounded,
        color: Color(0xFF2C5364),
      ),
      _SongPreviewData(
        title: 'Soft Morning',
        artist: 'Acoustic Mood',
        icon: Icons.wb_sunny_rounded,
        color: Color(0xFFE29578),
      ),
      _SongPreviewData(
        title: 'Deep Work',
        artist: 'Coding Beats',
        icon: Icons.code_rounded,
        color: Color(0xFF42275A),
      ),
    ];

    return Column(
      children: songs.map((song) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _SongListTile(song: song),
        );
      }).toList(),
    );
  }
}

class _SongCard extends StatelessWidget {
  final _SongPreviewData song;

  const _SongCard({
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.28),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: song.color,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              song.icon,
              color: Colors.white,
              size: 30,
            ),
          ),
          const Spacer(),
          Text(
            song.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            song.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SongListTile extends StatelessWidget {
  final _SongPreviewData song;

  const _SongListTile({
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: song.color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              song.icon,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SongPreviewData {
  final String title;
  final String artist;
  final IconData icon;
  final Color color;

  const _SongPreviewData({
    required this.title,
    required this.artist,
    required this.icon,
    required this.color,
  });
}