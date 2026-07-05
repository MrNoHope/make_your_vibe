import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/common_widgets.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageScroll(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                  const Spacer(),
                  const Text(
                    'PLAYING FROM BACKEND',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_vert_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const AlbumBox(size: 270),
              const SizedBox(height: 24),
              const Text(
                'No track loaded',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Music source backend is not connected yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.soft,
                ),
              ),
              const SizedBox(height: 24),
              Slider(
                value: 0,
                onChanged: null,
                activeColor: AppColors.green,
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0:00', style: TextStyle(color: AppColors.muted)),
                  Text('--:--', style: TextStyle(color: AppColors.muted)),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {},
                    iconSize: 32,
                    icon: const Icon(Icons.shuffle_rounded),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () {},
                    iconSize: 36,
                    icon: const Icon(Icons.skip_previous_rounded),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.green,
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 42,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {},
                    iconSize: 36,
                    icon: const Icon(Icons.skip_next_rounded),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () {},
                    iconSize: 32,
                    icon: const Icon(Icons.repeat_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const BackendNotice(
                icon: Icons.cloud_sync_rounded,
                title: 'Audio service phase',
                message:
                'Background playback, queue, notification control and real stream URL will be connected after UI is finished.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
