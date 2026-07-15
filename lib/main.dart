import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'controllers/app_controller.dart';
import 'services/audio_gateway.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ErrorWidget.builder = (details) => const _FriendlyErrorScreen();
  PlatformDispatcher.instance.onError = (error, stack) => true;

  try {
    final audioGateway = await _createAudioGateway();
    final controller = AppController(audio: audioGateway);
    await controller.init();
    runApp(MakeYourVibeApp(controller: controller));
  } catch (_) {
    runApp(const _StartupFallbackApp());
  }
}

Future<AudioGateway> _createAudioGateway() async {
  try {
    final audioHandler = await AudioService.init(
      builder: AudioGateway.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.mrnohope.makeyourvibe.v2.audio',
        androidNotificationChannelName: 'Make Your Vibe Playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
    return audioHandler as AudioGateway;
  } catch (_) {
    return AudioGateway();
  }
}

class _StartupFallbackApp extends StatelessWidget {
  const _StartupFallbackApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: _FriendlyErrorScreen()),
    );
  }
}

class _FriendlyErrorScreen extends StatelessWidget {
  const _FriendlyErrorScreen();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF080A0F),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.graphic_eq_rounded,
                size: 58,
                color: Color(0xFF74E26B),
              ),
              SizedBox(height: 16),
              Text(
                'Make Your Vibe chưa thể mở màn hình này. Hãy đóng và mở lại ứng dụng.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
