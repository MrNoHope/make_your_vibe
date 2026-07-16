class SupabaseConfig {
  static const _defaultPublishableKey =
      'sb_publishable_PCWJRwsAVkauw67S9XucQw_L5Kg6o85';

  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://diumqxbwtdpsyxmhptim.supabase.co',
  );
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get key {
    if (publishableKey.isNotEmpty) {
      return publishableKey;
    }
    if (anonKey.isNotEmpty) {
      return anonKey;
    }
    return _defaultPublishableKey;
  }

  static bool get isConfigured => url.isNotEmpty && key.isNotEmpty;
}
