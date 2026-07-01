import 'package:flutter/material.dart';

import '../../controllers/vibe_controller.dart';
import '../../core/app_colors.dart';
import '../../widgets/ambient_widgets.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/common_widgets.dart';

class AmbientMixerSheet extends StatelessWidget {
  const AmbientMixerSheet({
    super.key,
    required this.controller,
  });

  final VibeController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final active = controller.ambientLayers.where((layer) => layer.active).toList();

        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.45,
          maxChildSize: 0.94,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Bộ trộn âm nền',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    controller.activeLayerText,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 18),
                  MixerRow(
                    icon: Icons.music_note,
                    title: 'Nhạc chính',
                    value: controller.musicVolume,
                    onChanged: controller.setMusicVolume,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'ACTIVE LAYERS',
                          style: TextStyle(
                            color: AppColors.green,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: controller.pauseAllAmbient,
                        child: const Text('Pause All'),
                      ),
                      TextButton(
                        onPressed: controller.clearAmbient,
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                  if (active.isEmpty)
                    const EmptyPanel(text: 'No ambient')
                  else
                    ...active.map((layer) {
                      return MixerRow(
                        icon: layer.icon,
                        title: layer.name,
                        value: layer.volume,
                        active: layer.active,
                        onToggle: () => controller.toggleAmbient(layer),
                        onChanged: (value) => controller.setAmbientVolume(layer, value),
                      );
                    }),
                  const SizedBox(height: 18),
                  const Text(
                    'TAP TO ADD',
                    style: TextStyle(
                      color: AppColors.green,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    itemCount: controller.ambientLayers.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.34,
                    ),
                    itemBuilder: (context, index) {
                      final layer = controller.ambientLayers[index];

                      return AmbientCompactTile(
                        layer: layer,
                        onTap: () => controller.toggleAmbient(layer),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    text: 'Áp dụng',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
