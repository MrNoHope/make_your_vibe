import 'package:flutter/material.dart';

import '../../controllers/vibe_controller.dart';
import '../../core/app_colors.dart';
import '../../widgets/mini_player.dart';
import '../home/home_page.dart';
import '../library/library_page.dart';
import '../player/ambient_mixer_sheet.dart';
import '../player/player_screen.dart';
import '../search/search_page.dart';
import '../settings/profile_screen.dart';
import '../settings/settings_page.dart';
import '../sound/sound_effects_page.dart';
import 'app_drawer.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.controller,
    required this.onLogout,
  });

  final VibeController controller;
  final Future<void> Function() onLogout;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  void openPlayer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(controller: widget.controller),
      ),
    );
  }

  void openMixer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AmbientMixerSheet(controller: widget.controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        controller: widget.controller,
        onOpenPlayer: openPlayer,
        onOpenMixer: openMixer,
      ),
      SoundEffectsPage(
        controller: widget.controller,
        onOpenMixer: openMixer,
      ),
      SearchPage(
        controller: widget.controller,
        onOpenPlayer: openPlayer,
      ),
      LibraryPage(
        controller: widget.controller,
        onOpenPlayer: openPlayer,
      ),
      SettingsPage(
        controller: widget.controller,
        onLogout: widget.onLogout,
      ),
    ];

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Scaffold(
          drawer: AppDrawer(
            controller: widget.controller,
            selectedIndex: index,
            onSelect: (value) {
              Navigator.pop(context);
              setState(() {
                index = value;
              });
            },
            onLogout: widget.onLogout,
          ),
          appBar: AppBar(
            title: const Text(
              'Make Your Vibe',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(
                        controller: widget.controller,
                      ),
                    ),
                  );
                },
                icon: const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.green,
                  child: Text(
                    'MV',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: pages[index],
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 82,
                child: MiniPlayer(
                  controller: widget.controller,
                  onTap: openPlayer,
                ),
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            backgroundColor: AppColors.panel,
            selectedIndex: index,
            indicatorColor: AppColors.green.withOpacity(0.18),
            onDestinationSelected: (value) {
              setState(() {
                index = value;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.music_note),
                label: 'Music',
              ),
              NavigationDestination(
                icon: Icon(Icons.spa),
                label: 'Sound',
              ),
              NavigationDestination(
                icon: Icon(Icons.search),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Icon(Icons.library_music),
                label: 'Library',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}
