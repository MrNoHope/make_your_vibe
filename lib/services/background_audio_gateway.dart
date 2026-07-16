import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BackgroundAudioGateway {
  static const MethodChannel _channel =
      MethodChannel('make_your_vibe/audio_runtime');

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    _initialized = true;
  }

  Future<void> preparePlayback() async {
    await initialize();
    await requestNotificationPermission();

    try {
      final session = await AudioSession.instance;
      await session.setActive(true);
    } catch (_) {}
  }

  Future<void> releasePlayback() async {
    try {
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (_) {}
  }

  Future<bool> requestNotificationPermission() async {
    if (kIsWeb) {
      return true;
    }

    try {
      return await _channel.invokeMethod<bool>(
            'requestNotificationPermission',
          ) ??
          true;
    } catch (_) {
      return false;
    }
  }
}

final BackgroundAudioGateway backgroundAudioGateway = BackgroundAudioGateway();
