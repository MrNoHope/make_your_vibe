import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/controllers/app_locale_controller.dart';
import '../../player/controllers/vibe_player_controller.dart';

class VibeHeroCard extends StatelessWidget {
  const VibeHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final playerController = context.watch<VibePlayerController>();
    final language = context.watch<AppLocaleController>().currentLanguage;
    final preset = playerController.selectedPreset;
    final ambient = playerController.displayAmbient;
    final track = playerController.currentTrack;

    return Container(
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.26),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -20,
            child: Container(
              width: 148,
              height: 148,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.28),
                    Colors.white.withOpacity(0.04),
                  ],
                ),
              ),
              child: Icon(
                ambient.icon,
                color: Colors.white.withOpacity(0.88),
                size: 72,
              ),
            ),
          ),
          Positioned(
            right: 6,
            bottom: 4,
            child: GestureDetector(
              onTap: playerController.togglePlay,
              child: Container(
                width: 62,
                height: 62,
                decoration: const BoxDecoration(
                  color: AppColors.spotifyGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  playerController.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.black,
                  size: 38,
                ),
              ),
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.58,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR VIBE',
                  style: TextStyle(
                    color: AppColors.spotifyGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  preset.name(language),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 0.98,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${track.title} • ${playerController.ambientSummary(language)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  preset.description(language),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}