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

        return Material(
          color: AppColors.background2,
          child: InkWell(
            onTap: onTap,
            child: Container(
              height: 58,
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.line),
                ),
              ),
              child: Row(
                children: [
                  CoverImage(
                    url: song?.coverUrl ?? '',
                    size: 42,
                    radius: 12,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song?.title ?? 'Tìm bài hát để phát',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          song?.artist ?? 'Make Your Vibe',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: controller.togglePlay,
                    icon: Icon(
                      controller.resolving
                          ? Icons.hourglass_top_rounded
                          : controller.isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                      color: AppColors.green,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
