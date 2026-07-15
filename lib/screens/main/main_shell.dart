import 'package:flutter/material.dart';

import '../../app_dependencies.dart';
import '../ambient/ambient_page.dart';
import '../community/community_page.dart';
import '../home/home_page.dart';
import '../library/library_page.dart';
import '../profile/profile_page.dart';
import '../search/search_page.dart';
import 'side_rail.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.c});

  final AppController c;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      HomePage(c: widget.c, onNavigate: _navigate),
      SearchPage(c: widget.c),
      AmbientPage(c: widget.c),
      LibraryPage(c: widget.c),
      CommunityPage(c: widget.c),
      ProfilePage(c: widget.c),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final content = Column(
          children: [
            Expanded(
              child: RepaintBoundary(
                child: IndexedStack(index: index, children: pages),
              ),
            ),
            if (c.playerSong != null) MiniPlayer(c: c),
          ],
        );

        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                SideRail(currentIndex: index, onChanged: _navigate),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          body: content,
          bottomNavigationBar: _CompactNavigation(
            currentIndex: index,
            onChanged: _navigate,
          ),
        );
      },
    );
  }

  void _navigate(int value) {
    if (value == index) return;
    setState(() => index = value);
  }
}

class _CompactNavigation extends StatelessWidget {
  const _CompactNavigation({
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onChanged,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_rounded),
          label: 'Trang chủ',
        ),
        NavigationDestination(
          icon: Icon(Icons.search_rounded),
          label: 'Tìm kiếm',
        ),
        NavigationDestination(
          icon: Icon(Icons.graphic_eq_rounded),
          label: 'Vibe',
        ),
        NavigationDestination(
          icon: Icon(Icons.library_music_rounded),
          label: 'Thư viện',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_alt_rounded),
          label: 'Cộng đồng',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_rounded),
          label: 'Cá nhân',
        ),
      ],
    );
  }
}
