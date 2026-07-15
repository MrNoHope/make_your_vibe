import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../screens/player/player_screen.dart';
import 'media_widgets.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key, required this.c});

  final AppController c;

  @override
  Widget build(BuildContext context) {
    final song = c.playerSong;
    if (song == null) return const SizedBox.shrink();

    final loading = c.playerPhase == PlayerLoadPhase.resolving ||
        c.playerPhase == PlayerLoadPhase.loading;
    final failed = c.playerPhase == PlayerLoadPhase.error;

    return SafeArea(
      top: false,
      child: RepaintBoundary(
        child: Material(
          elevation: 8,
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PlayerScreen(c: c)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 360;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MiniProgress(c: c, loading: loading, failed: failed),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 7, 4, 7),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 46,
                            height: 46,
                            child: Cover(song: song, radius: 10),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _statusText(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: failed
                                            ? Theme.of(context)
                                                .colorScheme
                                                .error
                                            : null,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 2),
                          if (failed)
                            IconButton(
                              tooltip: c.tr('Thử lại', 'Retry'),
                              onPressed: c.retryPlayer,
                              icon: const Icon(Icons.refresh_rounded),
                            )
                          else
                            IconButton(
                              tooltip: c.playing
                                  ? c.tr('Tạm dừng', 'Pause')
                                  : c.tr('Phát', 'Play'),
                              onPressed: loading ? null : c.togglePlay,
                              icon: Icon(
                                c.playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                              ),
                            ),
                          if (!compact && !failed)
                            IconButton(
                              tooltip: c.tr('Bài tiếp theo', 'Next'),
                              onPressed: c.queue.length > 1 ? c.next : null,
                              icon: const Icon(Icons.skip_next_rounded),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _statusText() {
    switch (c.playerPhase) {
      case PlayerLoadPhase.resolving:
        return c.tr(
          'Đang chuẩn bị bài mới • bài hiện tại vẫn phát',
          'Preparing next track • current audio keeps playing',
        );
      case PlayerLoadPhase.loading:
        return c.tr('Sắp phát…', 'Almost ready…');
      case PlayerLoadPhase.error:
        return c.playerError;
      case PlayerLoadPhase.ready:
        return c.playing
            ? c.tr(
                'Đang phát • ${c.playerSong!.artist}',
                'Playing • ${c.playerSong!.artist}',
              )
            : c.tr(
                'Đã tạm dừng • ${c.playerSong!.artist}',
                'Paused • ${c.playerSong!.artist}',
              );
      case PlayerLoadPhase.idle:
        return c.playerSong!.artist;
    }
  }
}

class _MiniProgress extends StatelessWidget {
  const _MiniProgress({
    required this.c,
    required this.loading,
    required this.failed,
  });

  final AppController c;
  final bool loading;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return LinearProgressIndicator(
        minHeight: 3,
        color: Theme.of(context).colorScheme.primary,
      );
    }

    return ValueListenableBuilder<Duration>(
      valueListenable: c.positionNotifier,
      builder: (context, position, _) => ValueListenableBuilder<Duration>(
        valueListenable: c.durationNotifier,
        builder: (context, duration, _) {
          final progress = duration.inMilliseconds <= 0
              ? 0.0
              : (position.inMilliseconds / duration.inMilliseconds)
                  .clamp(0.0, 1.0)
                  .toDouble();
          return LinearProgressIndicator(
            value: progress,
            minHeight: 3,
            color: failed ? Theme.of(context).colorScheme.error : null,
          );
        },
      ),
    );
  }
}
