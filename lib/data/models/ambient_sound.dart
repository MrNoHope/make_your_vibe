import 'package:flutter/material.dart';

import '../../core/controllers/app_locale_controller.dart';

class AmbientSound {
  final String id;
  final String groupId;
  final String nameVi;
  final String nameEn;
  final String variantVi;
  final String variantEn;
  final String assetPath;
  final IconData icon;

  const AmbientSound({
    required this.id,
    required this.groupId,
    required this.nameVi,
    required this.nameEn,
    required this.variantVi,
    required this.variantEn,
    required this.assetPath,
    required this.icon,
  });

  String name(AppLanguage language) {
    return language == AppLanguage.vi ? nameVi : nameEn;
  }

  String variant(AppLanguage language) {
    return language == AppLanguage.vi ? variantVi : variantEn;
  }

  String displayName(AppLanguage language) {
    return '${name(language)} ${variant(language)}';
  }
}