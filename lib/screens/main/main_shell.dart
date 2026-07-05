import 'package:flutter/material.dart';

import '../../controllers/vibe_controller.dart';
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

  void openPlayer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PlayerScreen(),
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
        onOpenPlayer: openPlayer,
        onOpenSearch: () {
          setState(() {
            index = 3;
          });
        },
      ),
      SoundEffectsPage(onOpenMixer: openAmbientMixer),
      SoundEffectsPage(onOpenMixer: openAmbientMixer),
      const SearchPage(),
      const LibraryPage(),
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
                  MiniPlayerBar(onTap: openPlayer),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}