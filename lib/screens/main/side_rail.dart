import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/app_logo.dart';

class SideRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const SideRail({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _RailItem(Icons.home_rounded, 'Music'),
      _RailItem(Icons.graphic_eq_rounded, 'Sound'),
      _RailItem(Icons.tune_rounded, 'Mixer'),
      _RailItem(Icons.library_music_rounded, 'Library', pageIndex: 4),
      _RailItem(Icons.settings_rounded, 'Settings', pageIndex: 5),
      _RailItem(Icons.person_rounded, 'Profile', pageIndex: 6),
    ];

    return Container(
      width: 54,
      color: AppColors.background,
      child: Column(
        children: [
          const SizedBox(height: 12),
          const AppLogo(size: 26),
          const SizedBox(height: 22),
          ...List.generate(items.length, (i) {
            final item = items[i];
            final pageIndex = item.pageIndex ?? i;
            final selected = pageIndex == currentIndex;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Tooltip(
                message: item.label,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onChanged(pageIndex),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.green : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.icon,
                      color: selected ? Colors.black : AppColors.soft,
                      size: 19,
                    ),
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.line),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              size: 17,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _RailItem {
  final IconData icon;
  final String label;
  final int? pageIndex;

  const _RailItem(this.icon, this.label, {this.pageIndex});
}
