import 'package:flutter/material.dart';

import '../../controllers/vibe_controller.dart';
import '../../core/app_colors.dart';
import '../../widgets/common_widgets.dart';

class PlayerScreen extends StatelessWidget {
  final VibeController controller;

  const PlayerScreen({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final song = controller.currentSong;

            return PageScroll(
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                      const Spacer(),
                      const Text(
                        'NOW PLAYING',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.more_vert_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  CoverImage(
                    url: song?.coverUrl ?? '',
                    size: 270,
                    radius: 28,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    song?.title ?? 'Chưa chọn bài hát',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    song?.artist ?? 'Hãy search và bấm một bài để phát',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.soft,
                    ),
                  ),
                  const SizedBox(height: 24),
                  StreamBuilder<Duration?>(
                    stream: controller.audio.durationStream,
                    builder: (context, durationSnapshot) {
                      return StreamBuilder<Duration>(
                        stream: controller.audio.positionStream,
                        builder: (context, positionSnapshot) {
                          final position = positionSnapshot.data ?? Duration.zero;
                          final duration = durationSnapshot.data ?? song?.duration ?? Duration.zero;
                          final max = duration.inMilliseconds <= 0
                              ? 1.0
                              : duration.inMilliseconds.toDouble();
                          final current = position.inMilliseconds.clamp(0, max.toInt()).toDouble();

                          return Column(
                            children: [
                              Slider(
                                value: current,
                                min: 0,
                                max: max,
                                activeColor: AppColors.green,
                                onChanged: song == null
                                    ? null
                                    : (value) {
                                        controller.seek(
                                          Duration(milliseconds: value.toInt()),
                                        );
                                      },
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    controller.formatDuration(position),
                                    style: const TextStyle(color: AppColors.muted),
                                  ),
                                  Text(
                                    controller.formatDuration(duration),
                                    style: const TextStyle(color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {},
                        iconSize: 32,
                        icon: const Icon(Icons.shuffle_rounded),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: controller.previousSong,
                        iconSize: 36,
                        icon: const Icon(Icons.skip_previous_rounded),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.green,
                        ),
                        child: IconButton(
                          onPressed: controller.togglePlay,
                          icon: Icon(
                            controller.resolving
                                ? Icons.hourglass_top_rounded
                                : controller.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                            color: Colors.black,
                            size: 42,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: controller.nextSong,
                        iconSize: 36,
                        icon: const Icon(Icons.skip_next_rounded),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () {},
                        iconSize: 32,
                        icon: const Icon(Icons.repeat_rounded),
                      ),
                    ],
                  ),
                  if (controller.errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    BackendNotice(
                      icon: Icons.error_outline_rounded,
                      title: 'Lỗi phát nhạc',
                      message: controller.errorMessage,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
