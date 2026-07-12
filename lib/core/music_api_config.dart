class MusicApiConfig {
  static const baseUrl = String.fromEnvironment('MUSIC_API_BASE_URL');

  static String get effectiveBaseUrl {
    final configured = baseUrl.trim();

    return configured;
  }
}
