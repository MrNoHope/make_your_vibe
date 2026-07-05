import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/ambient_widgets.dart';

class AmbientMixerSheet extends StatelessWidget {
  const AmbientMixerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.line),
      ),
      child: SafeArea(
        top: false,
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
            const Row(
              children: [
                Icon(Icons.tune_rounded, color: AppColors.green),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ambient Mixer',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'No fake ambient audio is loaded. This sheet is only UI, ready for real audio layers.',
              style: TextStyle(
                color: AppColors.soft,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            const MixerSlider(title: 'Music layer', value: 0.72),
            const MixerSlider(title: 'Ambient layer 1', value: 0.55),
            const MixerSlider(title: 'Ambient layer 2', value: 0.35),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}