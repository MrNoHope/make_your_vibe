import 'package:flutter/material.dart';

import '../../controllers/vibe_controller.dart';
import '../../core/app_colors.dart';
import '../../widgets/ambient_widgets.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/song_widgets.dart';

// Trang chính hiển thị danh sách bài hát, mục gần đây và các đề xuất.
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.controller,
    required this.onOpenPlayer,
    required this.onOpenMixer,
  });

  final VibeController controller;
  final VoidCallback onOpenPlayer;
  final VoidCallback onOpenMixer;

  @override
  Widget build(BuildContext context) {
    // Khối này quyết định danh sách "Gần đây" để hiển thị cho người dùng.
    // Nếu chưa có lịch sử nghe thì dùng 4 bài đầu tiên từ toàn bộ thư viện làm dữ liệu dự phòng.
    final recent = controller.recentlyPlayed.isEmpty
        ? controller.songs.take(4).toList()
        : controller.recentlyPlayed.take(4).toList();

    return AppPage(
      child: ListView(
        // Khối ListView này là bố cục chính của trang Home, chứa các nhóm nội dung theo chiều dọc.
        // Padding tạo khoảng trống ở mép màn hình và dành chỗ cho bottom player ở dưới.
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 180),
        children: [
          // HeroCard là khối đầu trang nổi bật, dùng để thu hút và cho phép mở ngay player hoặc mixer.
          HeroCard(
            controller: controller,
            onPlay: () async {
              // Chọn bài hát hiện tại nếu có, nếu không thì chọn bài đầu tiên.
              await controller.playSong(
                controller.currentSong ?? controller.songs.first,
              );
              onOpenPlayer();
            },
            onOpenMixer: onOpenMixer,
          ),
          const SizedBox(height: 26),
          // Khối này là tiêu đề nhóm đầu tiên: "Gần đây".
          // SectionHeader giúp giữ phong cách giao diện nhất quán cho các nhóm nội dung.
          const SectionHeader(
            title: 'Gần đây',
            action: 'Xem tất cả',
          ),
          const SizedBox(height: 12),
          // Đây là vùng hiển thị bài hát gần đây theo kiểu danh sách ngang, rất phù hợp cho trải nghiệm lướt nhanh.
          SizedBox(
            height: 204,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recent.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final song = recent[index];

                return SongCard(
                  song: song,
                  onTap: () async {
                    await controller.playSong(song);
                    onOpenPlayer();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 28),
          // Khối này tạo tiêu đề cho nhóm đề xuất, giúp người dùng hiểu đây là danh sách gợi ý.
          const SectionHeader(
            title: 'Gợi ý cho bạn',
            action: 'Daily Mix',
          ),
          const SizedBox(height: 12),
          // Khối này hiển thị các bài đề xuất dưới dạng danh sách dọc, mỗi mục có thể được chạm để phát ngay.
          ...controller.songs.take(5).map((song) {
            return SongListTile(
              controller: controller,
              song: song,
              onTap: () async {
                await controller.playSong(song);
                onOpenPlayer();
              },
            );
          }),
          const SizedBox(height: 16),
          // AmbientBanner là khối cuối trang, dùng để mở bộ âm nền và tạo điểm nhấn cho trải nghiệm.
          AmbientBanner(
            controller: controller,
            onTap: onOpenMixer,
          ),
        ],
      ),
    );
  }
}

// Widget card lớn ở phần đầu trang với nút phát và mở bộ âm nền.
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.controller,
    required this.onPlay,
    required this.onOpenMixer,
  });

  final VibeController controller;
  final VoidCallback onPlay;
  final VoidCallback onOpenMixer;

  @override
  Widget build(BuildContext context) {
    // Container này tạo nền card lớn với màu gradient, bo góc và viền, để làm nổi bật phần đầu trang.
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0B2A12),
            Color(0xFF142016),
            Color(0xFF1E1E1E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trạng thái nổi bật của giao diện.
          const StatusPill(text: 'ATMOSPHERE ACTIVE'),
          const SizedBox(height: 18),
          // Tiêu đề chính của hero card.
          const Text(
            'Bạn muốn nghe gì?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          // Hiển thị lớp âm nền đang hoạt động.
          Text(
            controller.activeLayerText,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          // Đây là hàng nút hành động chính: một nút phát nhạc và một nút mở bộ âm nền.
          Row(
            children: [
              FilledButton.icon(
                onPressed: onPlay,
                icon: const Icon(Icons.play_arrow),
                label: const Text('PLAY'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: onOpenMixer,
                icon: const Icon(Icons.tune),
                label: const Text('Mở bộ âm nền'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
