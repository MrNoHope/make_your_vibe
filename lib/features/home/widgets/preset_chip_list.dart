import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/controllers/app_locale_controller.dart';
import '../../player/controllers/vibe_player_controller.dart';

class PresetChipList extends StatelessWidget {
  const PresetChipList({super.key});

  @override
  Widget build(BuildContext context) {
    final playerController = context.watch<VibePlayerController>();
    final language = context.watch<AppLocaleController>().currentLanguage;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: playerController.presets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final preset = playerController.presets[index];
          final isSelected = playerController.selectedPresetIndex == index;

          return GestureDetector(
            onTap: () => playerController.applyPreset(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : AppColors.glassWhite,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                preset.name(language),
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}