import 'package:flutter/material.dart';

import '../../controllers/vibe_controller.dart';
import '../../widgets/ambient_widgets.dart';
import '../../widgets/common_widgets.dart';

class SoundEffectsPage extends StatelessWidget {
  const SoundEffectsPage({
    super.key,
    required this.controller,
    required this.onOpenMixer,
  });

  final VibeController controller;
  final VoidCallback onOpenMixer;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 180),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Sound Effects',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusPill(text: '${controller.activeAmbientCount} active'),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Chọn âm nền để trộn cùng nhạc chính.'),
          const SizedBox(height: 22),
          AmbientBanner(
            controller: controller,
            onTap: onOpenMixer,
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'HIỆU ỨNG MÔI TRƯỜNG'),
          const SizedBox(height: 14),
          GridView.builder(
            itemCount: controller.ambientLayers.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.02,
            ),
            itemBuilder: (context, index) {
              final layer = controller.ambientLayers[index];

              return AmbientTile(
                layer: layer,
                onTap: () => controller.toggleAmbient(layer),
              );
            },
          ),
        ],
      ),
    );
  }
}
