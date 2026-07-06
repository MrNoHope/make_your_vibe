import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.make_your_vibe.player',
    androidNotificationChannelName: 'Make Your Vibe Player',
    androidNotificationOngoing: true,
  );

  runApp(const MakeYourVibeApp());
}