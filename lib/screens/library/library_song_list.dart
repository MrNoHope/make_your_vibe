import 'package:flutter/material.dart';

import '../../app_dependencies.dart';

class LibrarySongList extends StatelessWidget {
  const LibrarySongList({
    required this.c,
    required this.songs,
    required this.emptyText,
  });

  final AppController c;
  final List<Song> songs;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return EmptyState(icon: Icons.favorite_border, text: emptyText);
    }
    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (_, index) => SongTile(
        c: c,
        song: songs[index],
        queue: songs,
      ),
    );
  }
}

