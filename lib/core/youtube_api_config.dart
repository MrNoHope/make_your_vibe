class YoutubeApiConfig {
  static const _defaultApiKey = 'AIzaSyB3e9EXDmflORvcyHiU6gREcCkbhyFgxEc';

  static const apiKey = String.fromEnvironment(
    'YOUTUBE_API_KEY',
    defaultValue: _defaultApiKey,
  );
}
