class MusicApiConfig {
  static const baseUrl = String.fromEnvironment(
    'MUSIC_API_BASE_URL',
    defaultValue: 'http://localhost:8765',
  );
}
