import 'package:flutter/material.dart';

class Song {
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.category,
    required this.assetPath,
    required this.duration,
    required this.colors,
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final String category;
  final String assetPath;
  final Duration duration;
  final List<Color> colors;
}
