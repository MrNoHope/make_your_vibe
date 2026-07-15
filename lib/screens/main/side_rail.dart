import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class SideRail extends StatelessWidget {
  const SideRail({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const icons = [
      Icons.home_rounded,
      Icons.search_rounded,
      Icons.graphic_eq_rounded,
      Icons.library_music_rounded,
      Icons.people_alt_rounded,
      Icons.person_rounded,
    ];
    const labels = [
      'Trang chủ',
      'Tìm kiếm',
      'Vibe',
      'Thư viện',
      'Cộng đồng',
      'Cá nhân',
    ];

    return Container(
      width: 68,
      decoration: const BoxDecoration(
        color: AppColors.background2,
        border: Border(right: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 14),
            const Icon(
              Icons.graphic_eq_rounded,
              color: AppColors.green,
              size: 30,
            ),
            const SizedBox(height: 22),
            for (var index = 0; index < icons.length; index++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Tooltip(
                  message: labels[index],
                  child: IconButton.filledTonal(
                    onPressed: () => onChanged(index),
                    style: IconButton.styleFrom(
                      backgroundColor: currentIndex == index
                          ? AppColors.green.withValues(alpha: 0.18)
                          : Colors.transparent,
                      foregroundColor: currentIndex == index
                          ? AppColors.green
                          : AppColors.soft,
                    ),
                    icon: Icon(icons[index]),
                  ),
                ),
              ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: Icon(
                Icons.music_note_rounded,
                color: AppColors.muted,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
