import 'package:flutter/material.dart';

import '../../core/controllers/app_locale_controller.dart';

class VibePreset {
  final String id;
  final String nameVi;
  final String nameEn;
  final String subtitleVi;
  final String subtitleEn;
  final String descriptionVi;
  final String descriptionEn;
  final List<String> defaultAmbientIds;
  final IconData icon;
  final double musicVolume;
  final double ambientVolume;
  final List<Color> gradientColors;

  const VibePreset({
    required this.id,
    required this.nameVi,
    required this.nameEn,
    required this.subtitleVi,
    required this.subtitleEn,
    required this.descriptionVi,
    required this.descriptionEn,
    required this.defaultAmbientIds,
    required this.icon,
    required this.musicVolume,
    required this.ambientVolume,
    required this.gradientColors,
  });

  String name(AppLanguage language) {
    return language == AppLanguage.vi ? nameVi : nameEn;
  }

  String subtitle(AppLanguage language) {
    return language == AppLanguage.vi ? subtitleVi : subtitleEn;
  }

  String description(AppLanguage language) {
    return language == AppLanguage.vi ? descriptionVi : descriptionEn;
  }
}