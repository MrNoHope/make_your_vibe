import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/controllers/app_locale_controller.dart';
import '../../player/controllers/vibe_player_controller.dart';

class SoundEffectsPage extends StatelessWidget {
  const SoundEffectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final playerController = context.watch<VibePlayerController>();
    final language = context.watch<AppLocaleController>().currentLanguage;
    final isVietnamese = language == AppLanguage.vi;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isVietnamese ? 'Sound Effects' : 'Sound Effects',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isVietnamese
                ? 'Bật nhiều âm nền cùng lúc để tạo không gian riêng.'
                : 'Layer multiple ambient sounds to create your own space.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ActiveSoundSummary(playerController: playerController),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              itemCount: playerController.ambientSounds.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final sound = playerController.ambientSounds[index];
                final isActive = playerController.isAmbientActive(sound.id);
                final volume = playerController.ambientVolumeOf(sound.id);

                return _SoundEffectTile(
                  title: sound.name(language),
                  variant: sound.variant(language),
                  icon: sound.icon,
                  active: isActive,
                  volume: volume,
                  onTap: () => playerController.toggleAmbient(sound.id),
                  onVolumeChanged: (value) {
                    playerController.changeAmbientVolume(sound.id, value);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveSoundSummary extends StatelessWidget {
  final VibePlayerController playerController;

  const _ActiveSoundSummary({
    required this.playerController,
  });

  @override
  Widget build(BuildContext context) {
    final language = context.watch<AppLocaleController>().currentLanguage;
    final count = playerController.activeAmbients.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.28),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.spotifyGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.graphic_eq_rounded,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count sound layer${count == 1 ? '' : 's'} active',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  playerController.ambientSummary(language),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

class _SoundEffectTile extends StatelessWidget {
  final String title;
  final String variant;
  final IconData icon;
  final bool active;
  final double volume;
  final VoidCallback onTap;
  final ValueChanged<double> onVolumeChanged;

  const _SoundEffectTile({
    required this.title,
    required this.variant,
    required this.icon,
    required this.active,
    required this.volume,
    required this.onTap,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: active
            ? AppColors.spotifyGreen.withOpacity(0.2)
            : Colors.black.withOpacity(0.24),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: active
              ? AppColors.spotifyGreen.withOpacity(0.7)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: active ? AppColors.spotifyGreen : Colors.white12,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: active ? Colors.black : Colors.white,
                    size: 27,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  variant,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (active)
                  SizedBox(
                    height: 30,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2.5,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 5,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 10,
                        ),
                      ),
                      child: Slider(
                        value: volume,
                        min: 0,
                        max: 1,
                        activeColor: AppColors.spotifyGreen,
                        inactiveColor: Colors.white24,
                        onChanged: onVolumeChanged,
                      ),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Tap to add',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
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