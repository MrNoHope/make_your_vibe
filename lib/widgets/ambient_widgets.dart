import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class SoundSlot extends StatelessWidget {
  final String title;
  final IconData icon;

  const SoundSlot({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.green.withValues(alpha: 0.12),
            child: Icon(
              icon,
              color: AppColors.green,
              size: 20,
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Asset pending',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class MixerSlider extends StatelessWidget {
  final String title;
  final double value;

  const MixerSlider({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        Slider(
          value: value,
          onChanged: (_) {},
          activeColor: AppColors.green,
        ),
      ],
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