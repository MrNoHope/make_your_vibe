import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/ambient_layer.dart';
import '../../services/ambient_audio_gateway.dart';
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
    return AnimatedBuilder(
      animation: ambientAudioGateway,
      builder: (context, _) {
        final gateway = ambientAudioGateway;
        final layers = gateway.layers;

        return PageScroll(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TopBar(
                title: 'Sound Effects',
                action: IconButton(
                  tooltip: 'Mixer',
                  onPressed: onOpenMixer,
                  icon: const Icon(Icons.tune_rounded),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                height: 118,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: AppColors.mainGradient,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.graphic_eq_rounded,
                      color: AppColors.green,
                      size: 42,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        '${gateway.activeCount} active layers',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          height: 1.15,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Stop all',
                      onPressed: gateway.activeCount == 0
                          ? null
                          : () => gateway.stopAll(),
                      icon: const Icon(Icons.stop_circle_rounded),
                    ),
                  ],
                ),
              ),
              if (gateway.errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                BackendNotice(
                  icon: Icons.error_outline_rounded,
                  title: 'Sound effect error',
                  message: gateway.errorMessage,
                ),
              ],
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
                childAspectRatio: 0.94,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final layer in layers)
                    SoundSlot(
                      layer: layer,
                      icon: _ambientIcon(layer),
                      loading: gateway.isLoading(layer.id),
                      onTap: () => gateway.toggleLayer(layer.id),
                      onVolumeChanged: (value) {
                        gateway.setLayerVolume(layer.id, value);
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _ambientIcon(AmbientLayer layer) {
    return switch (layer.id) {
      'rain' => Icons.water_drop_rounded,
      'waves' => Icons.waves_rounded,
      'fire' => Icons.local_fire_department_rounded,
      'wind' => Icons.air_rounded,
      'cafe' => Icons.local_cafe_rounded,
      'noise' => Icons.blur_on_rounded,
      _ => Icons.graphic_eq_rounded,
    };
  }
}
