import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../services/ambient_audio_gateway.dart';
import '../../widgets/ambient_widgets.dart';

class AmbientMixerSheet extends StatelessWidget {
  const AmbientMixerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambientAudioGateway,
      builder: (context, _) {
        final gateway = ambientAudioGateway;

        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.line),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Icon(Icons.tune_rounded, color: AppColors.green),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Ambient Mixer',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
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
                  const SizedBox(height: 12),
                  MixerSlider(
                    title: 'Master',
                    value: gateway.masterVolume,
                    onChanged: (value) {
                      gateway.setMasterVolume(value);
                    },
                  ),
                  const SizedBox(height: 4),
                  for (final layer in gateway.layers)
                    MixerSlider(
                      title: layer.name,
                      value: layer.volume,
                      onChanged: (value) {
                        gateway.setLayerVolume(layer.id, value);
                      },
                      trailing: Switch(
                        value: layer.active,
                        activeThumbColor: AppColors.green,
                        onChanged: gateway.isLoading(layer.id)
                            ? null
                            : (value) {
                                gateway.setLayerActive(layer.id, value);
                              },
                      ),
                    ),
                  if (gateway.errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      gateway.errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
