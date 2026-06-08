import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/controllers/app_navigation_controller.dart';
import '../../player/controllers/vibe_player_controller.dart';
import '../widgets/music_landing_page.dart';
import '../widgets/side_navigation_bar.dart';
import '../widgets/sound_effects_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navigation = context.watch<AppNavigationController>();
    final controller = context.watch<VibePlayerController>();
    final preset = controller.selectedPreset;

    final currentPage = navigation.currentSection == AppMainSection.music
        ? const MusicLandingPage()
        : const SoundEffectsPage();

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              preset.gradientColors.first,
              preset.gradientColors.last,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              const SideNavigationBar(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: KeyedSubtree(
                    key: ValueKey(navigation.currentSection),
                    child: currentPage,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}