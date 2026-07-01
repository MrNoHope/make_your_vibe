import 'package:flutter/material.dart';

import '../../controllers/vibe_controller.dart';
import '../../models/song.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/song_widgets.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({
    super.key,
    required this.controller,
    required this.onOpenPlayer,
  });

  final VibeController controller;
  final VoidCallback onOpenPlayer;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  List<Song> get results {
    final query = search.text.trim().toLowerCase();

    if (query.isEmpty) {
      return widget.controller.songs;
    }

    return widget.controller.songs.where((song) {
      return song.title.toLowerCase().contains(query) ||
          song.artist.toLowerCase().contains(query) ||
          song.album.toLowerCase().contains(query) ||
          song.category.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 180),
        children: [
          const Text(
            'Search',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Bạn muốn nghe gì?',
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Khám phá thể loại'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              GenreChip(text: 'Pop'),
              GenreChip(text: 'Lofi'),
              GenreChip(text: 'Study'),
              GenreChip(text: 'Chill'),
              GenreChip(text: 'Acoustic'),
              GenreChip(text: 'Instrumental'),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Kết quả'),
          const SizedBox(height: 8),
          ...results.map((song) {
            return SongListTile(
              controller: widget.controller,
              song: song,
              onTap: () async {
                await widget.controller.playSong(song);
                widget.onOpenPlayer();
              },
            );
          }),
        ],
      ),
    );
  }
}
