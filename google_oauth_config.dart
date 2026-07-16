class GoogleOAuthConfig {
  static const webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '194875375112-9u34urjv890d7onio46gjhgid764nl2k.apps.googleusercontent.com',
  );

  static String? get serverClientId {
    final value = webClientId.trim();
    return value.isEmpty ? null : value;
  }
}
