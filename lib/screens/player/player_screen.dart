import 'dart:async';
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
                    final mediaSize = (constraints.maxWidth - 40)
                        .clamp(230.0, 360.0)
                        .toDouble();

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
                            const SizedBox(height: 16),
                            Center(
                              child: SizedBox.square(
                                dimension: mediaSize,
                                child: _HeroMedia(song: song),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                song?.title ?? 'Chưa chọn bài hát',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 25,
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
                                _RepeatControlButton(controller: controller),
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

class _HeroMedia extends StatelessWidget {
  final Song? song;

  const _HeroMedia({
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    final url = song?.coverUrl.trim() ?? '';
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.darkGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(
        child: Icon(
          Icons.music_note_rounded,
          color: AppColors.green,
          size: 64,
        ),
      ),
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      foregroundDecoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: url.isEmpty
          ? fallback
          : Image.network(
              url,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
              loadingBuilder: (context, child, progress) {
                if (progress == null) {
                  return child;
                }

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    fallback,
                    const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
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

class _ProgressBlock extends StatefulWidget {
  final VibeController controller;
  final Song? song;

  const _ProgressBlock({
    required this.controller,
    required this.song,
  });

  @override
  State<_ProgressBlock> createState() => _ProgressBlockState();
}

class _ProgressBlockState extends State<_ProgressBlock> {
  double? _dragValue;
  Timer? _seekDebounce;

  @override
  void dispose() {
    _seekDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final position = widget.controller.position;
    final duration =
        widget.controller.duration ?? widget.song?.duration ?? Duration.zero;
    final max =
        duration.inMilliseconds <= 0 ? 1.0 : duration.inMilliseconds.toDouble();
    final current =
        (_dragValue ?? position.inMilliseconds.toDouble()).clamp(0.0, max);
    final shownPosition = Duration(milliseconds: current.toInt());

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
            onChanged: widget.song == null
                ? null
                : (value) {
                    setState(() => _dragValue = value);
                    _seekDebounce?.cancel();
                    _seekDebounce = Timer(
                      const Duration(milliseconds: 350),
                      () => _commitSeek(value),
                    );
                  },
            onChangeEnd: widget.song == null
                ? null
                : (value) async {
                    _seekDebounce?.cancel();
                    await _commitSeek(value);
                  },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.controller.formatDuration(shownPosition),
              style: const TextStyle(color: AppColors.soft),
            ),
            Text(
              widget.controller.formatDuration(duration),
              style: const TextStyle(color: AppColors.soft),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _commitSeek(double value) async {
    if (!mounted) {
      return;
    }

    setState(() => _dragValue = value);
    await widget.controller.seek(Duration(milliseconds: value.toInt()));

    if (mounted) {
      setState(() => _dragValue = null);
    }
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

class _RepeatControlButton extends StatelessWidget {
  final VibeController controller;

  const _RepeatControlButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    final repeatMode = controller.repeatMode;
    final active = repeatMode != VibeRepeatMode.off;

    return SizedBox(
      width: 48,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: switch (repeatMode) {
              VibeRepeatMode.off => 'Lap lai',
              VibeRepeatMode.song => 'Lap lai bai hien tai',
              VibeRepeatMode.songOnce => 'Lap lai bai nay 1 lan',
            },
            onPressed: controller.currentSong == null
                ? null
                : controller.cycleRepeatMode,
            iconSize: 34,
            color: active ? AppColors.green2 : Colors.white,
            disabledColor: AppColors.muted,
            icon: Icon(
              repeatMode == VibeRepeatMode.songOnce
                  ? Icons.repeat_one_rounded
                  : Icons.repeat_rounded,
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: active ? 5 : 0,
            height: active ? 5 : 0,
            decoration: const BoxDecoration(
              color: AppColors.green2,
              shape: BoxShape.circle,
            ),
          ),
        ],
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
