import 'package:flutter/material.dart';

import '../../controllers/vibe_controller.dart';
import '../../core/app_colors.dart';
import '../../widgets/ambient_widgets.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/song_widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.controller,
    required this.onOpenPlayer,
    required this.onOpenMixer,
  });

  final VibeController controller;
  final VoidCallback onOpenPlayer;
  final VoidCallback onOpenMixer;

  @override
  Widget build(BuildContext context) {
    final recent = controller.recentlyPlayed.isEmpty
        ? controller.songs.take(4).toList()
        : controller.recentlyPlayed.take(4).toList();

    return AppPage(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 180),
        children: [
          HeroCard(
            controller: controller,
            onPlay: () async {
              await controller.playSong(
                controller.currentSong ?? controller.songs.first,
              );
              onOpenPlayer();
            },
            onOpenMixer: onOpenMixer,
          ),
          const SizedBox(height: 26),
          const SectionHeader(
            title: 'Gần đây',
            action: 'Xem tất cả',
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 204,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recent.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final song = recent[index];

                return SongCard(
                  song: song,
                  onTap: () async {
                    await controller.playSong(song);
                    onOpenPlayer();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 28),
          const SectionHeader(
            title: 'Gợi ý cho bạn',
            action: 'Daily Mix',
          ),
          const SizedBox(height: 12),
          ...controller.songs.take(5).map((song) {
            return SongListTile(
              controller: controller,
              song: song,
              onTap: () async {
                await controller.playSong(song);
                onOpenPlayer();
              },
            );
          }),
          const SizedBox(height: 16),
          AmbientBanner(
            controller: controller,
            onTap: onOpenMixer,
          ),
        ],
      ),
    );
  }
}

class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.controller,
    required this.onPlay,
    required this.onOpenMixer,
  });

  final VibeController controller;
  final VoidCallback onPlay;
  final VoidCallback onOpenMixer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0B2A12),
            Color(0xFF142016),
            Color(0xFF1E1E1E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusPill(text: 'ATMOSPHERE ACTIVE'),
          const SizedBox(height: 18),
          const Text(
            'Bạn muốn nghe gì?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.activeLayerText,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              FilledButton.icon(
                onPressed: onPlay,
                icon: const Icon(Icons.play_arrow),
                label: const Text('PLAY'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: onOpenMixer,
                icon: const Icon(Icons.tune),
                label: const Text('Mở bộ âm nền'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
