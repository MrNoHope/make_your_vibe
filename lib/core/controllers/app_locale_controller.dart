import 'package:flutter/material.dart';

enum AppLanguage {
  vi,
  en,
}

class AppLocaleController extends ChangeNotifier {
  AppLanguage currentLanguage = AppLanguage.vi;

  bool get isVietnamese {
    return currentLanguage == AppLanguage.vi;
  }

  void changeLanguage(AppLanguage language) {
    currentLanguage = language;
    notifyListeners();
  }
}