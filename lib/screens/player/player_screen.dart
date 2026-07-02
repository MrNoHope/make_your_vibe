import 'package:flutter/material.dart';

import '../../controllers/vibe_controller.dart';
import '../../core/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/ambient_widgets.dart';
import '../../widgets/song_widgets.dart';
import 'ambient_mixer_sheet.dart';

// Màn hình phát nhạc chi tiết, hiển thị bài hát đang phát, tiến trình và các nút điều khiển.
class PlayerScreen extends StatelessWidget {
  const PlayerScreen({
    super.key,
    required this.controller,
  });

  final VibeController controller;

  @override
  Widget build(BuildContext context) {
    // Khối này chuẩn bị dữ liệu phát nhạc cho toàn bộ màn hình player.
    // Nếu chưa có bài nào đang phát thì dùng bài đầu tiên trong danh sách làm dữ liệu mặc định.
    final song = controller.currentSong ?? controller.songs.first;
    // maxMs là tổng thời lượng bài hát, dùng để giới hạn thanh tua nhạc đúng phạm vi.
    final maxMs = controller.duration.inMilliseconds > 0
        ? controller.duration.inMilliseconds.toDouble()
        : song.duration.inMilliseconds.toDouble();

    // currentMs là vị trí hiện tại đang phát, được giới hạn lại để slider không vượt quá maxMs.
    final currentMs = controller.position.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // AnimatedBuilder giúp màn hình tự làm mới khi trạng thái phát nhạc, thời gian, hoặc bài hát thay đổi.
        // Mỗi lần controller đổi, currentSong sẽ được cập nhật để UI phản ánh đúng trạng thái hiện tại.
        final currentSong = controller.currentSong ?? song;

        return Scaffold(
          appBar: AppBar(
            // AppBar ở đây đóng vai trò thanh tiêu đề cho màn hình player, cho biết đang phát từ playlist nào.
            centerTitle: true,
            title: const Column(
              children: [
                Text(
                  'PLAYING FROM PLAYLIST',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.green,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Daily Mix',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          body: ListView(
            // ListView cho phép nội dung cuộn nếu màn hình quá dài, ví dụ khi thông tin bài hát hoặc nút điều khiển nhiều.
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            children: [
              // Ảnh bìa của bài đang phát.
              Center(
                child: CoverArt(
                  song: currentSong,
                  size: 280,
                ),
              ),
              const SizedBox(height: 30),
              // Khối này chứa tên bài hát, tên nghệ sĩ và nút thích để lưu vào danh sách yêu thích.
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentSong.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentSong.artist,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => controller.toggleLiked(currentSong),
                    icon: Icon(
                      controller.isLiked(currentSong) ? Icons.favorite : Icons.favorite_border,
                      color: controller.isLiked(currentSong) ? AppColors.green : Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Slider là thanh tua nhạc, cho phép người dùng kéo để chuyển nhanh đến một vị trí nhất định trong bài.
              Slider(
                value: currentMs,
                min: 0,
                max: maxMs,
                onChanged: controller.seek,
              ),
              // Hiển thị thời gian đang phát và tổng thời lượng.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatDuration(controller.position)),
                  Text(
                    formatDuration(
                      controller.duration == Duration.zero ? currentSong.duration : controller.duration,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Hàng nút điều khiển trung tâm bao gồm quay lại, phát/tạm dừng và chuyển tiếp bài tiếp theo.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: controller.playPrevious,
                    icon: const Icon(
                      Icons.skip_previous,
                      size: 42,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: controller.togglePlay,
                    icon: Icon(
                      controller.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                      color: AppColors.green,
                      size: 78,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: controller.playNext,
                    icon: const Icon(
                      Icons.skip_next,
                      size: 42,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Khối cuối cùng mở một cửa sổ nổi để người dùng điều chỉnh các lớp âm nền đang phát.
              AmbientBanner(
                controller: controller,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => AmbientMixerSheet(controller: controller),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
