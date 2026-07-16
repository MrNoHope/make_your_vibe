enum AppLanguage {
  vi,
  en,
}

extension AppLanguageText on AppLanguage {
  bool get isVietnamese => this == AppLanguage.vi;

  String get label {
    return isVietnamese ? 'Tiếng Việt' : 'English';
  }

  String text({
    required String vi,
    required String en,
  }) {
    return isVietnamese ? vi : en;
  }
}
