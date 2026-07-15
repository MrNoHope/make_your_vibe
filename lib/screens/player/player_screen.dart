import 'package:flutter/material.dart';

import '../../app_dependencies.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key, required this.c});

  final AppController c;

  @override
  Widget build(BuildContext context) {
    final song = c.playerSong;
    if (song == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.music_off_rounded,
          text: c.tr('Chưa chọn bài hát.', 'No track selected.'),
        ),
      );
    }

    final loading = c.playerPhase == PlayerLoadPhase.resolving ||
        c.playerPhase == PlayerLoadPhase.loading;
    final failed = c.playerPhase == PlayerLoadPhase.error;

    return Scaffold(
      appBar: AppBar(
        title: Text(c.tr('Đang phát', 'Now playing')),
        actions: [
          IconButton(
            tooltip: c.tr('Chia sẻ', 'Share'),
            onPressed: () => c.shareText('${song.title} - ${song.artist}'),
            icon: const Icon(Icons.share_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final artSize = (constraints.maxWidth - 48).clamp(220.0, 390.0);
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
              children: [
                Center(
                  child: SizedBox(
                    width: artSize,
                    height: artSize,
                    child: Cover(song: song, radius: 30, iconSize: 96),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  song.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                if (loading)
                  _StatusCard(
                    icon: const Icon(Icons.downloading_rounded),
                    text: c.playerPhase == PlayerLoadPhase.resolving
                        ? c.tr(
                            'Đang chuẩn bị bài mới. Bạn vẫn có thể bấm bài khác hoặc chuyển tiếp.',
                            'Preparing the new track. You can still select another track or skip.',
                          )
                        : c.tr(
                            'Luồng đã sẵn sàng, đang đệm âm thanh…',
                            'Stream ready, buffering audio…',
                          ),
                  )
                else if (failed)
                  _StatusCard(
                    icon: Icon(
                      Icons.info_outline_rounded,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    text: c.playerError,
                    action: FilledButton.tonalIcon(
                      onPressed: c.retryPlayer,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(c.tr('Thử lại', 'Retry')),
                    ),
                  ),
                _ProgressSection(c: c, enabled: !loading && !failed),
                const SizedBox(height: 8),
                _PrimaryControls(c: c, loading: loading, failed: failed),
                const SizedBox(height: 10),
                _SecondaryControls(c: c, song: song),
                if (c.queue.length > 1) ...[
                  const SizedBox(height: 20),
                  SectionTitle(c.tr('Tiếp theo', 'Up next')),
                  const SizedBox(height: 4),
                  for (final queued in c.queue.skip(c.queueIndex + 1).take(5))
                    SongTile(c: c, song: queued, queue: c.queue),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.c, required this.enabled});

  final AppController c;
  final bool enabled;

  String _format(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: c.positionNotifier,
      builder: (context, position, _) => ValueListenableBuilder<Duration>(
        valueListenable: c.durationNotifier,
        builder: (context, duration, _) {
          final songDuration = c.playerSong?.duration ?? Duration.zero;
          final effectiveDuration = duration > Duration.zero
              ? duration
              : songDuration > Duration.zero
                  ? songDuration
                  : const Duration(milliseconds: 1);
          final safePosition = position > effectiveDuration
              ? effectiveDuration
              : position;
          return Column(
            children: [
              Slider(
                value: safePosition.inMilliseconds.toDouble(),
                max: effectiveDuration.inMilliseconds.toDouble(),
                onChanged: enabled
                    ? (value) => c.seek(
                          Duration(milliseconds: value.round()),
                        )
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_format(safePosition)),
                    Text(_format(effectiveDuration)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PrimaryControls extends StatelessWidget {
  const _PrimaryControls({
    required this.c,
    required this.loading,
    required this.failed,
  });

  final AppController c;
  final bool loading;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final small = constraints.maxWidth < 330;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              tooltip: c.tr('Bài trước', 'Previous'),
              onPressed: c.queue.isEmpty ? null : c.previous,
              iconSize: small ? 29 : 34,
              icon: const Icon(Icons.skip_previous_rounded),
            ),
            if (!small)
              IconButton(
                tooltip: c.tr('Lùi 10 giây', 'Back 10 seconds'),
                onPressed: loading || failed
                    ? null
                    : () => c.seekBy(const Duration(seconds: -10)),
                icon: const Icon(Icons.replay_10_rounded),
              ),
            IconButton.filled(
              onPressed: loading ? null : c.togglePlay,
              iconSize: small ? 38 : 43,
              padding: EdgeInsets.all(small ? 14 : 17),
              icon: Icon(
                failed
                    ? Icons.refresh_rounded
                    : c.playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
              ),
            ),
            if (!small)
              IconButton(
                tooltip: c.tr('Tiến 10 giây', 'Forward 10 seconds'),
                onPressed: loading || failed
                    ? null
                    : () => c.seekBy(const Duration(seconds: 10)),
                icon: const Icon(Icons.forward_10_rounded),
              ),
            IconButton(
              tooltip: c.tr('Bài tiếp theo', 'Next'),
              onPressed: c.queue.length > 1 ? c.next : null,
              iconSize: small ? 29 : 34,
              icon: const Icon(Icons.skip_next_rounded),
            ),
          ],
        );
      },
    );
  }
}

class _SecondaryControls extends StatelessWidget {
  const _SecondaryControls({required this.c, required this.song});

  final AppController c;
  final Song song;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 6,
      children: [
        IconButton(
          tooltip: c.tr('Phát ngẫu nhiên', 'Shuffle'),
          onPressed: c.toggleShuffle,
          icon: Icon(
            Icons.shuffle_rounded,
            color: c.shuffleEnabled
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
        ),
        IconButton(
          tooltip: c.tr('Yêu thích', 'Like'),
          onPressed: () => c.toggleLike(song),
          icon: Icon(
            c.liked.contains(song.id)
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: c.liked.contains(song.id) ? Colors.pink : null,
          ),
        ),
        IconButton(
          tooltip: c.tr('Thêm vào playlist', 'Add to playlist'),
          onPressed: () => _playlist(context),
          icon: const Icon(Icons.playlist_add_rounded),
        ),
        IconButton(
          tooltip: c.tr('Chế độ lặp', 'Repeat mode'),
          onPressed: c.cycleRepeatMode,
          icon: Icon(
            c.repeatMode == QueueRepeatMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            color: c.repeatMode == QueueRepeatMode.off
                ? null
                : Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Future<void> _playlist(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            ListTile(
              title: Text(c.tr('Thêm vào playlist', 'Add to playlist')),
              trailing: IconButton(
                onPressed: () => Navigator.pop(sheetContext),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            if (c.playlists.isEmpty)
              ListTile(
                title: Text(
                  c.tr(
                    'Hãy tạo playlist trong Thư viện trước.',
                    'Create a playlist in Library first.',
                  ),
                ),
              ),
            for (final playlist in c.playlists)
              ListTile(
                leading: const Icon(Icons.queue_music_rounded),
                title: Text(
                  playlist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  c.addToPlaylist(playlist.id, song);
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.icon, required this.text, this.action});

  final Widget icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            icon,
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 160, maxWidth: 360),
              child: Text(text),
            ),
            if (action != null) action!,
          ],
        ),
      ),
    );
  }
}
