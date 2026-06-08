import 'package:flutter/material.dart';

enum AppMainSection {
  music,
  soundEffects,
}

class AppNavigationController extends ChangeNotifier {
  AppMainSection currentSection = AppMainSection.music;

  void changeSection(AppMainSection section) {
    currentSection = section;
    notifyListeners();
  }
}