import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/supabase_gateway.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _tryInitializeFirebase();
  await _tryInitializeSupabase();

  if (!kIsWeb) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.make_your_vibe.player',
      androidNotificationChannelName: 'Make Your Vibe Player',
      androidNotificationOngoing: true,
    );
  }

  runApp(const MakeYourVibeApp());
}

Future<void> _tryInitializeFirebase() async {
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
    } else {
      await Firebase.initializeApp();
    }
  } catch (_) {
    // Firebase config is added after the Firebase project is created.
  }
}

Future<void> _tryInitializeSupabase() async {
  try {
    await supabaseGateway.initialize();
  } catch (_) {
    // Supabase stays disabled until the project URL/key are valid.
  }
}
