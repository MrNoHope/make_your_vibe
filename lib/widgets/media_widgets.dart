import 'dart:io';

import 'package:flutter/material.dart';

import '../models/models.dart';

class Cover extends StatelessWidget {
  const Cover({
    super.key,
    required this.song,
    this.radius = 12,
    this.iconSize = 36,
  });

  final Song song;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (song.artworkUrl.startsWith('http')) {
      child = Image.network(
        song.artworkUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    } else if (song.artworkUrl.isNotEmpty &&
        File(song.artworkUrl).existsSync()) {
      child = Image.file(
        File(song.artworkUrl),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    } else {
      child = _fallback(context);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: child,
    );
  }

  Widget _fallback(BuildContext context) => Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        alignment: Alignment.center,
        child: Icon(Icons.music_note, size: iconSize),
      );
}

class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.path,
    required this.radius,
  });

  final String path;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final file = path.isEmpty ? null : File(path);
    final valid = file != null && file.existsSync();
    final fallback = ColoredBox(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Center(child: Icon(Icons.person, size: radius)),
    );

    return SizedBox.square(
      dimension: radius * 2,
      child: ClipOval(
        child: valid
            ? Image.file(
                file,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
              )
            : fallback,
      ),
    );
  }
}
