import 'dart:ui';

import 'package:flutter/material.dart';

import '../../controllers/vibe_controller.dart';
import '../../core/app_colors.dart';
import '../../models/song.dart';
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
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final song = controller.currentSong;

          return Stack(
            children: [
              _PlayerBackdrop(coverUrl: song?.coverUrl ?? ''),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 30,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Đóng',
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 32,
                                  ),
                                ),
                                const Expanded(
                                  child: Text(
                                    'NOW PLAYING',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.soft,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Tùy chọn',
                                  onPressed: () {},
                                  icon: const Icon(Icons.more_vert_rounded),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            AspectRatio(
                              aspectRatio: 1,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 330,
                                  maxHeight: 330,
                                ),
                                child: CoverImage(
                                  url: song?.coverUrl ?? '',
                                  size: double.infinity,
                                  radius: 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                song?.title ?? 'Chưa chọn bài hát',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 28,
                                  height: 1.08,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                song?.artist ??
                                    'Hãy search và bấm một bài để phát',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.soft,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _AlbumInfoBlock(song: song),
                            const SizedBox(height: 18),
                            _ProgressBlock(controller: controller, song: song),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _PlainControlButton(
                                  tooltip: 'Lùi 10 giây',
                                  icon: Icons.replay_10_rounded,
                                  onPressed: song == null
                                      ? null
                                      : controller.rewindTenSeconds,
                                ),
                                _PlainControlButton(
                                  tooltip: 'Bài trước',
                                  icon: Icons.skip_previous_rounded,
                                  iconSize: 44,
                                  onPressed: song == null
                                      ? null
                                      : controller.previousSong,
                                ),
                                _PlayButton(controller: controller),
                                _PlainControlButton(
                                  tooltip: 'Bài sau',
                                  icon: Icons.skip_next_rounded,
                                  iconSize: 44,
                                  onPressed:
                                      song == null ? null : controller.nextSong,
                                ),
                                _PlainControlButton(
                                  tooltip: 'Dừng',
                                  icon: Icons.stop_circle_rounded,
                                  onPressed:
                                      song == null ? null : controller.reset,
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
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AlbumInfoBlock extends StatelessWidget {
  final Song? song;

  const _AlbumInfoBlock({required this.song});

  @override
  Widget build(BuildContext context) {
    final album = song == null
        ? 'No album'
        : song!.album.trim().isNotEmpty
            ? song!.album.trim()
            : song!.artist.trim().isNotEmpty
                ? song!.artist.trim()
                : 'Single';
    final duration = song?.durationText ?? '--:--';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          CoverImage(
            url: song?.coverUrl ?? '',
            size: 46,
            radius: 7,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Album',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  album,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            duration,
            style: const TextStyle(
              color: AppColors.soft,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerBackdrop extends StatelessWidget {
  final String coverUrl;

  const _PlayerBackdrop({required this.coverUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (coverUrl.trim().isNotEmpty)
          Image.network(
            coverUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: const SizedBox.expand(),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.28),
                AppColors.background.withValues(alpha: 0.78),
                Colors.black.withValues(alpha: 0.94),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressBlock extends StatelessWidget {
  final VibeController controller;
  final Song? song;

  const _ProgressBlock({
    required this.controller,
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: controller.audio.durationStream,
      builder: (context, durationSnapshot) {
        return StreamBuilder<Duration>(
          stream: controller.audio.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final duration =
                durationSnapshot.data ?? song?.duration ?? Duration.zero;
            final max = duration.inMilliseconds <= 0
                ? 1.0
                : duration.inMilliseconds.toDouble();
            final current =
                position.inMilliseconds.clamp(0, max.toInt()).toDouble();

            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                  ),
                  child: Slider(
                    value: current,
                    min: 0,
                    max: max,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white.withValues(alpha: 0.28),
                    onChanged: song == null
                        ? null
                        : (value) {
                            controller.seek(
                              Duration(milliseconds: value.toInt()),
                            );
                          },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      controller.formatDuration(position),
                      style: const TextStyle(color: AppColors.soft),
                    ),
                    Text(
                      controller.formatDuration(duration),
                      style: const TextStyle(color: AppColors.soft),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PlayButton extends StatelessWidget {
  final VibeController controller;

  const _PlayButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 78,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          tooltip: controller.isPlaying ? 'Tạm dừng' : 'Phát',
          onPressed: controller.resolving ? null : controller.togglePlay,
          icon: Icon(
            controller.resolving
                ? Icons.hourglass_top_rounded
                : controller.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
            color: Colors.black,
            size: 44,
          ),
        ),
      ),
    );
  }
}

class _PlainControlButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final double iconSize;
  final VoidCallback? onPressed;

  const _PlainControlButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.iconSize = 34,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: iconSize,
      color: Colors.white,
      disabledColor: AppColors.muted,
      icon: Icon(icon),
    );
  }
}
