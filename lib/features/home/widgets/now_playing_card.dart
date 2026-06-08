import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/controllers/app_locale_controller.dart';
import '../../player/controllers/vibe_player_controller.dart';

class NowPlayingCard extends StatelessWidget {
  const NowPlayingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final playerController = context.watch<VibePlayerController>();
    final language = context.watch<AppLocaleController>().currentLanguage;
    final preset = playerController.selectedPreset;
    final ambient = playerController.displayAmbient;
    final track = playerController.currentTrack;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            gradient: RadialGradient(
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.12),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Icon(
            ambient.icon,
            size: 112,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          preset.name(language),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${track.title} • ${playerController.ambientSummary(language)}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          preset.description(language),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.72),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}