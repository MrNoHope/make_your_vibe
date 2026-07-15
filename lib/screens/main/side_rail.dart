import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.soft : AppColors.lightSoft;
    final mutedColor = isDark ? AppColors.muted : AppColors.lightMuted;
    final lineColor = isDark ? AppColors.line : AppColors.lightLine;
    final items = [
      _RailItem(Icons.home_rounded, 'Music'),
      _RailItem(Icons.tune_rounded, 'Sound'),
      _RailItem(Icons.library_music_rounded, 'Library', pageIndex: 3),
      _RailItem(Icons.settings_rounded, 'Settings', pageIndex: 4),
      _RailItem(Icons.person_rounded, 'Profile', pageIndex: 5),
    ];

    return Container(
      width: 54,
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          const SizedBox(height: 20),
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
                      color: selected ? Colors.black : iconColor,
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
              border: Border.all(color: lineColor),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_off_rounded,
              size: 17,
              color: mutedColor,
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
