import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/ambient_widgets.dart';
import '../../widgets/common_widgets.dart';

class SoundEffectsPage extends StatelessWidget {
  final VoidCallback onOpenMixer;

  const SoundEffectsPage({
    super.key,
    required this.onOpenMixer,
  });

  @override
  Widget build(BuildContext context) {
    return PageScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TopBar(
            title: 'Sound Effects',
            action: IconButton(
              onPressed: onOpenMixer,
              icon: const Icon(Icons.tune_rounded),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 138,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: AppColors.mainGradient,
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.graphic_eq_rounded,
                  color: AppColors.green,
                  size: 42,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Ambient mixer UI is ready. Sound files will be added later.',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Ambient layers',
            action: 'Mixer',
            onTap: onOpenMixer,
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 11,
            mainAxisSpacing: 11,
            childAspectRatio: 1.05,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              SoundSlot(title: 'Rain slot', icon: Icons.water_drop_rounded),
              SoundSlot(title: 'Wave slot', icon: Icons.waves_rounded),
              SoundSlot(title: 'Fire slot', icon: Icons.local_fire_department_rounded),
              SoundSlot(title: 'Wind slot', icon: Icons.air_rounded),
              SoundSlot(title: 'Cafe slot', icon: Icons.local_cafe_rounded),
              SoundSlot(title: 'Noise slot', icon: Icons.blur_on_rounded),
            ],
          ),
        ],
      ),
    );
  }
}