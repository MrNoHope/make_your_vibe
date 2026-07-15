import 'package:flutter/material.dart';

import '../../app_dependencies.dart';
import 'library_playlists.dart';
import 'library_song_list.dart';
import 'library_uploads.dart';
import 'library_vibes.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, required this.c});

  final AppController c;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage>
    with SingleTickerProviderStateMixin {
  late final TabController tabController = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return Scaffold(
      appBar: AppBar(
        title: Text(c.tr('Thư viện', 'Library')),
        bottom: TabBar(
          controller: tabController,
          isScrollable: true,
          tabs: [
            Tab(text: c.tr('Đã thích', 'Liked')),
            Tab(text: c.tr('Playlist', 'Playlists')),
            Tab(text: c.tr('Vibe đã lưu', 'Saved Vibes')),
            Tab(text: c.tr('Nhạc của tôi', 'My uploads')),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          LibrarySongList(
            c: c,
            songs: c.likedSongs,
            emptyText: c.tr(
              'Chưa có bài hát đã thích.',
              'No liked songs yet.',
            ),
          ),
          LibraryPlaylists(c: c),
          LibraryVibes(c: c),
          LibraryUploads(c: c),
        ],
      ),
    );
  }
}

