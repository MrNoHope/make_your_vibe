class GoogleOAuthConfig {
  static const webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  static String? get serverClientId {
    final value = webClientId.trim();
    return value.isEmpty ? null : value;
  }
}
