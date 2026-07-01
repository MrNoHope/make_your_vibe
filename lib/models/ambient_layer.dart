import 'package:flutter/material.dart';

class AmbientLayer {
  AmbientLayer({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.icon,
    required this.group,
    this.volume = 0.45,
    this.active = false,
  });

  final String id;
  final String name;
  final String assetPath;
  final IconData icon;
  final String group;
  double volume;
  bool active;
}
