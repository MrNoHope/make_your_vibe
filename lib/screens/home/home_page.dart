import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/song_widgets.dart';

class HomePage extends StatelessWidget {
  final VoidCallback onOpenPlayer;
  final VoidCallback onOpenSearch;

  const HomePage({
    super.key,
    required this.onOpenPlayer,
    required this.onOpenSearch,
  });

  @override
  Widget build(BuildContext context) {
    return PageScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TopBar(
            title: 'Make Your Vibe',
            action: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ),
          const SizedBox(height: 14),
          HeroMusicCard(onTap: onOpenPlayer),
          const SizedBox(height: 20),
          SectionHeader(
            title: 'Daily Mix',
            action: 'See all',
            onTap: onOpenSearch,
          ),
          const SizedBox(height: 12),
          const BackendPlaceholderGrid(),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'For your mood',
            action: 'Backend',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          const BackendNotice(
            icon: Icons.dns_rounded,
            title: 'Waiting for music source',
            message:
            'Home cards, album covers, songs and artists will be loaded from the music backend.',
          ),
        ],
      ),
    );
  }
}

class HeroMusicCard extends StatelessWidget {
  final VoidCallback onTap;

  const HeroMusicCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 166,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: AppColors.mainGradient,
        ),
        child: Stack(
          children: [
            Positioned(
              right: -6,
              bottom: -8,
              child: Icon(
                Icons.album_rounded,
                size: 112,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connect your\nmusic source',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: 185,
                  child: Text(
                    'The UI is ready. Real songs will come from backend.',
                    style: TextStyle(
                      color: AppColors.soft,
                      height: 1.35,
                      fontSize: 12,
                    ),
                  ),
                ),
                Spacer(),
                SmallGreenButton(label: 'Open player'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}