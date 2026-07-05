import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import 'common_widgets.dart';

class PlaceholderAlbumCard extends StatelessWidget {
  final String title;

  const PlaceholderAlbumCard({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: AlbumBox(size: double.infinity),
          ),
          const SizedBox(height: 9),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Backend data',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class BackendPlaceholderGrid extends StatelessWidget {
  const BackendPlaceholderGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.86,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        PlaceholderAlbumCard(title: 'Song card slot'),
        PlaceholderAlbumCard(title: 'Album card slot'),
        PlaceholderAlbumCard(title: 'Artist card slot'),
        PlaceholderAlbumCard(title: 'Playlist card slot'),
      ],
    );
  }
}