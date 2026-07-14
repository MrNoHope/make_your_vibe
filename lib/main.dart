import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/audio_gateway.dart';
import 'services/background_audio_gateway.dart';
import 'services/supabase_gateway.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _tryInitializeFirebase();
  await _tryInitializeSupabase();

  if (!kIsWeb) {
    await audioGateway.initialize();
  }
  await backgroundAudioGateway.initialize();

  runApp(const MakeYourVibeApp());
}

Future<void> _tryInitializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Firebase config is added after the Firebase project is created.
  }
}

Future<void> _tryInitializeSupabase() async {
  try {
    await supabaseGateway.initialize();
  } catch (_) {
    // Supabase is optional until upload storage is configured.
  }
}
