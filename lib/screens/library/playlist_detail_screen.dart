import 'package:flutter/material.dart';

import '../../controllers/vibe_controller.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/song_widgets.dart';

class PlaylistDetailScreen extends StatelessWidget {
  const PlaylistDetailScreen({
    super.key,
    required this.controller,
    required this.onOpenPlayer,
  });

  final VibeController controller;
  final VoidCallback onOpenPlayer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlist'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
        children: [
          Center(
            child: CoverArt(
              song: controller.songs.first,
              size: 190,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Daily Mix',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Playlist • Chill, Lo-fi',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            text: 'PLAY',
            onPressed: () async {
              await controller.playSong(controller.songs.first);
              onOpenPlayer();
            },
          ),
          const SizedBox(height: 22),
          ...controller.songs.map((song) {
            return SongListTile(
              controller: controller,
              song: song,
              onTap: () async {
                await controller.playSong(song);
                onOpenPlayer();
              },
            );
          }),
        ],
      ),
    );
  }
}
