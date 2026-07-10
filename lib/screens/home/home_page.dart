import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../controllers/vibe_controller.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/song_widgets.dart';

class HomePage extends StatefulWidget {
  final VibeController controller;
  final VoidCallback onOpenPlayer;
  final VoidCallback onOpenSearch;

  const HomePage({
    super.key,
    required this.controller,
    required this.onOpenPlayer,
    required this.onOpenSearch,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kIsWeb) {
        widget.controller.loadHomeSongs();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return PageScroll(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TopBar(
                title: 'Make Your Vibe',
                action: IconButton(
                  onPressed: widget.onOpenSearch,
                  icon: const Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Nhạc gợi ý',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              if (widget.controller.loadingHome)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (widget.controller.homeSongs.isNotEmpty)
                SongList(
                  songs: widget.controller.homeSongs,
                  activeId: widget.controller.currentSong?.id,
                  activePlaying: widget.controller.isPlaying,
                  activeBusy: widget.controller.resolving,
                  onSongTap: (song) {
                    widget.controller.playSong(
                      song,
                      queue: widget.controller.homeSongs,
                    );
                  },
                  onActiveToggle: widget.controller.togglePlay,
                  onActiveStop: widget.controller.reset,
                  onActiveOpen: widget.onOpenPlayer,
                ),
              if (widget.controller.errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                BackendNotice(
                  icon: Icons.error_outline_rounded,
                  title: 'Lỗi phát nhạc',
                  message: widget.controller.errorMessage,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
