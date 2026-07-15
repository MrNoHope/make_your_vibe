import 'package:flutter/material.dart';

import '../../controllers/vibe_controller.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/song_widgets.dart';
import 'playlist_detail_screen.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({
    super.key,
    required this.controller,
    required this.onOpenPlayer,
  });

  final VibeController controller;
  final VoidCallback onOpenPlayer;

  @override
  Widget build(BuildContext context) {
    final liked = controller.likedSongs;  // Hiển thị danh sách nhạc và playlist đã lưu

    return AppPage(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 180),
        children: [
          const Text(
            'Thư viện',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.32,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              LibraryCard(
                icon: Icons.favorite,
                title: 'Bài hát đã thích',
                subtitle: '${liked.length} bài hát',
                onTap: () {},
              ),
              LibraryCard(
                icon: Icons.history,
                title: 'Gần đây',
                subtitle: '${controller.recentlyPlayed.length} bài hát',
                onTap: () {},
              ),
              // Mở màn hình chi tiết playlist Daily Mix
              LibraryCard(
                icon: Icons.playlist_play,
                title: 'Daily Mix',  
                subtitle: 'Playlist • 248 bài hát',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlaylistDetailScreen(
                        controller: controller,
                        onOpenPlayer: onOpenPlayer,
                      ),
                    ),
                  );
                },
              ),
              LibraryCard(
                icon: Icons.spa,
                title: 'Saved Vibes',
                subtitle: '${controller.savedVibes.length} vibe preset',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Bài hát đã thích'),
          const SizedBox(height: 8),
          if (liked.isEmpty)
            const EmptyPanel(text: 'Chưa có bài hát đã thích.')
          else
            ...liked.map((song) {   // Hiển thị thông báo nếu chưa có bài hát yêu thích
              return SongListTile(
                controller: controller,
                song: song,
                onTap: () async {
                  await controller.playSong(song);   // Phát bài hát được chọn và mở màn hình trình phát nhạc
                  onOpenPlayer();
                },
              );
            }),
        ],
      ),
    );
  }
}
