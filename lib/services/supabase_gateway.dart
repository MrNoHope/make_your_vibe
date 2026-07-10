import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';

class SupabaseConfigException implements Exception {
  final String message;

  const SupabaseConfigException(this.message);

  @override
  String toString() => message;
}

class SupabaseGateway {
  SupabaseClient? _client;
  Future<SupabaseClient?>? _initFuture;

  bool get isConfigured => SupabaseConfig.isConfigured;

  Future<SupabaseClient?> initialize() {
    if (_client != null) {
      return Future.value(_client);
    }

    if (!SupabaseConfig.isConfigured) {
      return Future.value(null);
    }

    _initFuture ??= _initializeConfigured();
    return _initFuture!;
  }

  Future<SupabaseClient> requireClient() async {
    final client = await initialize();

    if (client == null) {
      throw const SupabaseConfigException(
        'Missing SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY or SUPABASE_ANON_KEY.',
      );
    }

    return client;
  }

  Future<SupabaseClient?> _initializeConfigured() async {
    try {
      final supabase = await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.key,
        accessToken: _firebaseAccessToken,
      );
      _client = supabase.client;
      return _client;
    } catch (_) {
      _initFuture = null;
      rethrow;
    }
  }

  Future<String?> _firebaseAccessToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {
      return null;
    }
  }
}

final supabaseGateway = SupabaseGateway();
