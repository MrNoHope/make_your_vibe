import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/ambient_layer.dart';

class SoundSlot extends StatelessWidget {
  final AmbientLayer layer;
  final IconData icon;
  final bool loading;
  final VoidCallback onTap;
  final ValueChanged<double> onVolumeChanged;

  const SoundSlot({
    super.key,
    required this.layer,
    required this.icon,
    required this.loading,
    required this.onTap,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final active = layer.active;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color:
              active ? AppColors.green.withValues(alpha: 0.13) : AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? AppColors.green : AppColors.line,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: active
                      ? AppColors.green
                      : AppColors.green.withValues(alpha: 0.12),
                  child: loading
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          icon,
                          color: active ? Colors.black : AppColors.green,
                          size: 20,
                        ),
                ),
                const Spacer(),
                Icon(
                  active
                      ? Icons.pause_circle_rounded
                      : Icons.play_arrow_rounded,
                  color: active ? AppColors.green : AppColors.soft,
                ),
              ],
            ),
            const Spacer(),
            Text(
              layer.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              active ? 'On' : 'Off',
              style: TextStyle(
                color: active ? AppColors.green : AppColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 5,
                  disabledThumbRadius: 5,
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 12,
                ),
              ),
              child: Slider(
                value: layer.volume,
                min: 0,
                max: 1,
                onChanged: onVolumeChanged,
                activeColor: AppColors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MixerSlider extends StatelessWidget {
  final String title;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final Widget? trailing;

  const MixerSlider({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final percent = '${(value * 100).round()}%';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                percent,
                style: const TextStyle(
                  color: AppColors.soft,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 1,
              onChanged: enabled ? onChanged : null,
              activeColor: AppColors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class MixerPreviewTile extends StatelessWidget {
  final String title;
  final double value;
  final VoidCallback onTap;

  const MixerPreviewTile({
    super.key,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.graphic_eq_rounded,
            color: AppColors.green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Slider(
                  value: value,
                  onChanged: (_) {},
                  activeColor: AppColors.green,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onTap,
            icon: const Icon(Icons.open_in_full_rounded),
          ),
        ],
      ),
    );
  }
}
