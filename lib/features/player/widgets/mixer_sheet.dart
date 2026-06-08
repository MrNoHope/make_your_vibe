import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_texts.dart';
import '../../../core/controllers/app_locale_controller.dart';
import '../controllers/vibe_player_controller.dart';

class MixerSheet extends StatelessWidget {
  const MixerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final playerController = context.watch<VibePlayerController>();
    final language = context.watch<AppLocaleController>().currentLanguage;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.78,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppTexts.personalMixer(language),
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: playerController.toggleMusicLoop,
                      icon: Icon(
                        Icons.repeat_rounded,
                        color: playerController.isMusicLoopEnabled
                            ? AppColors.spotifyGreen
                            : Colors.white54,
                      ),
                    ),
                  ],
                ),
                if (playerController.audioError != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      playerController.audioError!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _MusicVolumeCard(playerController: playerController),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: ListView.separated(
                    itemCount: playerController.ambientSounds.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final sound = playerController.ambientSounds[index];
                      final isActive = playerController.isAmbientActive(sound.id);
                      final volume = playerController.ambientVolumeOf(sound.id);

                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.spotifyGreen.withOpacity(0.18)
                              : AppColors.surfaceSoft.withOpacity(0.74),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isActive
                                ? AppColors.spotifyGreen.withOpacity(0.55)
                                : Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  sound.icon,
                                  color: isActive ? AppColors.spotifyGreen : Colors.white,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sound.name(language),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        sound.variant(language),
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: isActive,
                                  activeColor: AppColors.spotifyGreen,
                                  onChanged: (_) => playerController.toggleAmbient(sound.id),
                                ),
                              ],
                            ),
                            if (isActive)
                              Slider(
                                value: volume,
                                min: 0,
                                max: 1,
                                activeColor: AppColors.spotifyGreen,
                                inactiveColor: Colors.white24,
                                onChanged: (value) {
                                  playerController.changeAmbientVolume(sound.id, value);
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MusicVolumeCard extends StatelessWidget {
  final VibePlayerController playerController;

  const _MusicVolumeCard({
    required this.playerController,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (playerController.musicVolume * 100).round();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft.withOpacity(0.74),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.music_note_rounded, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'Music',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Slider(
            value: playerController.musicVolume,
            min: 0,
            max: 1,
            activeColor: AppColors.spotifyGreen,
            inactiveColor: Colors.white24,
            onChanged: playerController.changeMusicVolume,
          ),
        ],
      ),
    );
  }
}