import 'package:flutter/material.dart';

import '../../controllers/vibe_controller.dart';
import '../../core/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/ambient_widgets.dart';
import '../../widgets/song_widgets.dart';
import 'ambient_mixer_sheet.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({
    super.key,
    required this.controller,
  });

  final VibeController controller;

  @override
  Widget build(BuildContext context) {
    final song = controller.currentSong ?? controller.songs.first;
    final maxMs = controller.duration.inMilliseconds > 0
        ? controller.duration.inMilliseconds.toDouble()
        : song.duration.inMilliseconds.toDouble();

    final currentMs = controller.position.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final currentSong = controller.currentSong ?? song;

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Column(
              children: [
                Text(
                  'PLAYING FROM PLAYLIST',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.green,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Daily Mix',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            children: [
              Center(
                child: CoverArt(
                  song: currentSong,
                  size: 280,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentSong.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentSong.artist,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => controller.toggleLiked(currentSong),
                    icon: Icon(
                      controller.isLiked(currentSong) ? Icons.favorite : Icons.favorite_border,
                      color: controller.isLiked(currentSong) ? AppColors.green : Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Slider(
                value: currentMs,
                min: 0,
                max: maxMs,
                onChanged: controller.seek,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatDuration(controller.position)),
                  Text(
                    formatDuration(
                      controller.duration == Duration.zero ? currentSong.duration : controller.duration,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: controller.playPrevious,
                    icon: const Icon(
                      Icons.skip_previous,
                      size: 42,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: controller.togglePlay,
                    icon: Icon(
                      controller.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                      color: AppColors.green,
                      size: 78,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: controller.playNext,
                    icon: const Icon(
                      Icons.skip_next,
                      size: 42,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AmbientBanner(
                controller: controller,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => AmbientMixerSheet(controller: controller),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
