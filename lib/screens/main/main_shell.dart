import 'package:flutter/material.dart';
import '../../controllers/vibe_controller.dart';
import '../../core/app_colors.dart';
import '../../core/app_language.dart';
import '../../screens/home/home_page.dart';
import '../../screens/library/library_page.dart';
import '../../screens/main/side_rail.dart';
import '../../screens/player/ambient_mixer_sheet.dart';
import '../../screens/player/player_screen.dart';
import '../../screens/search/search_page.dart';
import '../../screens/settings/profile_screen.dart';
import '../../screens/settings/settings_page.dart';
import '../../screens/sound/sound_effects_page.dart';
import '../../widgets/mini_player.dart';

class MainShell extends StatefulWidget {
  final VibeController controller;
  final VoidCallback onLogout;

  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final AppLanguage language;
  final VoidCallback onLanguageChanged;

  const MainShell({
    super.key,
    required this.controller,
    required this.onLogout,
    required this.darkMode,
    required this.onDarkModeChanged,
    required this.language,
    required this.onLanguageChanged,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  Future<void> openPlayer() async {
    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: ColoredBox(
            color: AppColors.background,
            child: PlayerScreen(controller: widget.controller),
          ),
        ),
      ),
    );
  }

  void openAmbientMixer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const AmbientMixerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        controller: widget.controller,
        onOpenPlayer: openPlayer,
        onOpenSearch: () {
          setState(() {
            index = 2;
          });
        },
      ),
      SoundEffectsPage(onOpenMixer: openAmbientMixer),
      SearchPage(
        controller: widget.controller,
        onOpenPlayer: openPlayer,
      ),
      LibraryPage(
        controller: widget.controller,
        onOpenPlayer: openPlayer,
        onOpenSearch: () {
          setState(() {
            index = 2;
          });
        },
      ),
      SettingsPage(
        onLogout: widget.onLogout,
        darkMode: widget.darkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
        language: widget.language,
        onLanguageChanged: widget.onLanguageChanged,
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Row(
          children: [
            SideRail(
              currentIndex: index,
              onChanged: (value) {
                if (value < 0) {
                  openAmbientMixer();
                  return;
                }

                setState(() {
                  index = value;
                });
              },
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: pages[index],
                  ),
                  MiniPlayerBar(
                    controller: widget.controller,
                    onTap: openPlayer,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
