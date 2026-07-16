import 'package:flutter/material.dart';

import '../controllers/vibe_controller.dart';
import '../core/app_colors.dart';
import 'common_widgets.dart';

class MiniPlayerBar extends StatelessWidget {
  final VibeController controller;
  final VoidCallback onTap;

  const MiniPlayerBar({
    super.key,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final song = controller.currentSong;

        if (song == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onTap,
              child: Container(
                height: 64,
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    _MiniArtwork(
                      coverUrl: song.coverUrl,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist.isEmpty
                                ? 'Make Your Vibe'
                                : song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.soft,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 136,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _MiniControlButton(
                            tooltip: 'Bài trước',
                            icon: Icons.skip_previous_rounded,
                            onPressed: controller.previousSong,
                          ),
                          _MiniControlButton(
                            tooltip: controller.isPlaying ? 'Tạm dừng' : 'Phát',
                            icon: controller.resolving
                                ? Icons.hourglass_top_rounded
                                : controller.isPlaying
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_fill_rounded,
                            iconSize: 34,
                            onPressed: controller.resolving
                                ? null
                                : controller.togglePlay,
                          ),
                          _MiniControlButton(
                            tooltip: 'Bài sau',
                            icon: Icons.skip_next_rounded,
                            onPressed: controller.nextSong,
                          ),
                          _MiniRepeatButton(controller: controller),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniArtwork extends StatelessWidget {
  final String coverUrl;

  const _MiniArtwork({
    required this.coverUrl,
  });

  @override
  Widget build(BuildContext context) {
    return CoverImage(
      url: coverUrl,
      size: 50,
      radius: 6,
    );
  }
}

class _MiniControlButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final double iconSize;
  final VoidCallback? onPressed;

  const _MiniControlButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.iconSize = 25,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 32,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: onPressed == null ? AppColors.muted : Colors.white,
          size: iconSize,
        ),
      ),
    );
  }
}

class _MiniRepeatButton extends StatelessWidget {
  final VibeController controller;

  const _MiniRepeatButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    final repeatMode = controller.repeatMode;
    final active = repeatMode != VibeRepeatMode.off;

    return SizedBox.square(
      dimension: 32,
      child: IconButton(
        tooltip: switch (repeatMode) {
          VibeRepeatMode.off => 'Lap lai',
          VibeRepeatMode.song => 'Lap lai bai hien tai',
          VibeRepeatMode.songOnce => 'Lap lai bai nay 1 lan',
        },
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed:
            controller.currentSong == null ? null : controller.cycleRepeatMode,
        icon: Icon(
          repeatMode == VibeRepeatMode.songOnce
              ? Icons.repeat_one_rounded
              : Icons.repeat_rounded,
          color: active ? AppColors.green2 : Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
