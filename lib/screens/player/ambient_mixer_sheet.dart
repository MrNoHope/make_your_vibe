import 'package:flutter/material.dart';

import '../sound/sound_effects_page.dart';

class AmbientMixerSheet extends StatelessWidget {
  const AmbientMixerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.92;

    return SafeArea(
      child: SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16),
          ),
          child: ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: const SoundEffectsPage(),
          ),
        ),
      ),
    );
  }
}
