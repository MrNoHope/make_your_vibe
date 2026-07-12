import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';

class SupabaseConfigException implements Exception {
  final String message;

  const SupabaseConfigException(this.message);

  @override
  String toString() => message;
}

class SupabaseUploadResult {
  final String bucket;
  final String path;
  final String publicUrl;

  const SupabaseUploadResult({
    required this.bucket,
    required this.path,
    required this.publicUrl,
  });
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

  Future<SupabaseUploadResult> uploadBinary({
    required String bucket,
    required String objectPath,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final client = await requireClient();
    final storage = client.storage.from(bucket);

    await storage.uploadBinary(
      objectPath,
      bytes,
      fileOptions: FileOptions(
        contentType: contentType,
        cacheControl: '604800',
        upsert: false,
      ),
    );

    return SupabaseUploadResult(
      bucket: bucket,
      path: objectPath,
      publicUrl: storage.getPublicUrl(objectPath),
    );
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
