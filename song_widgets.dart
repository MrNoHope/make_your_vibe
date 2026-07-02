import 'package:flutter/material.dart';

import '../controllers/vibe_controller.dart';
import '../core/app_colors.dart';
import '../models/song.dart';

class CoverArt extends StatelessWidget {
  const CoverArt({
    super.key,
    required this.song,
    required this.size,
  });

  final Song song;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size > 160 ? 34 : 20),
        gradient: LinearGradient(
          colors: song.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: song.colors.last.withOpacity(0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.42,
          height: size * 0.42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.album,
            color: song.colors.first,
            size: size * 0.22,
          ),
        ),
      ),
    );
  }
}

class SongCard extends StatelessWidget {
  const SongCard({
    super.key,
    required this.song,
    required this.onTap,
  });

  final Song song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 142,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CoverArt(song: song, size: 142),
            const SizedBox(height: 10),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SongListTile extends StatelessWidget {
  const SongListTile({
    super.key,
    required this.controller,
    required this.song,
    required this.onTap,
  });

  final VibeController controller;
  final Song song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        tileColor: AppColors.panel,
        leading: CoverArt(song: song, size: 54),
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${song.artist} • ${song.category}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          onPressed: () => controller.toggleLiked(song),
          icon: Icon(
            controller.isLiked(song) ? Icons.favorite : Icons.favorite_border,
            color: controller.isLiked(song) ? AppColors.green : Colors.white70,
          ),
        ),
      ),
    );
  }
}
