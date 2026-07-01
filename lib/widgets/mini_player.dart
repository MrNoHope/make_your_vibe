import 'package:flutter/material.dart';

import '../controllers/vibe_controller.dart';
import '../core/app_colors.dart';
import 'song_widgets.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({
    super.key,
    required this.controller,
    required this.onTap,
  });

  final VibeController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final song = controller.currentSong;

    if (song == null) {
      return const SizedBox.shrink();
    }

    return Material(
      color: AppColors.panel2,
      elevation: 16,
      shadowColor: Colors.black54,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              CoverArt(song: song, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      controller.activeLayerText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: controller.togglePlay,
                icon: Icon(
                  controller.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  color: AppColors.green,
                  size: 38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
