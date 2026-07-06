import 'package:flutter/material.dart';

import '../../controllers/vibe_controller.dart';
import '../../core/app_colors.dart';
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
      widget.controller.loadHomeSongs();
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
              HeroMusicCard(onTap: widget.onOpenSearch),
              const SizedBox(height: 20),
              SectionHeader(
                title: 'Nhạc gợi ý',
                action: 'Search',
                onTap: widget.onOpenSearch,
              ),
              const SizedBox(height: 12),
              if (widget.controller.loadingHome)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                SongList(
                  songs: widget.controller.homeSongs,
                  activeId: widget.controller.currentSong?.id,
                  onSongTap: (song) {
                    widget.controller.playSong(
                      song,
                      queue: widget.controller.homeSongs,
                    );
                  },
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

class HeroMusicCard extends StatelessWidget {
  final VoidCallback onTap;

  const HeroMusicCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 166,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: AppColors.mainGradient,
        ),
        child: Stack(
          children: [
            Positioned(
              right: -6,
              bottom: -8,
              child: Icon(
                Icons.album_rounded,
                size: 112,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search and\nplay music',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: 185,
                  child: Text(
                    'Nhập tên bài hát, chọn kết quả và phát trực tiếp.',
                    style: TextStyle(
                      color: AppColors.soft,
                      height: 1.35,
                      fontSize: 12,
                    ),
                  ),
                ),
                Spacer(),
                SmallGreenButton(label: 'Search music'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
