import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/common_widgets.dart';

class PlaylistDetailScreen extends StatelessWidget {
  const PlaylistDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {  // Màn hình chi tiết Playlist: Hiển thị thông tin và danh sách bài hát
    return Scaffold(
      body: SafeArea(
        child: PageScroll(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TopBar(
                title: 'Playlist',
                action: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              const SizedBox(height: 16),
              const AlbumBox(size: 180),
              const SizedBox(height: 18),
              const Text(
                'Playlist backend slot',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Songs will be loaded from user backend',
                style: TextStyle(color: AppColors.soft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
