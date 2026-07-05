import '../models/song.dart';

abstract class AudioGateway {
  Future<void> play(Song song);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
}

class EmptyAudioGateway implements AudioGateway {
  const EmptyAudioGateway();

  @override
  Future<void> play(Song song) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}
}

const AudioGateway audioGateway = EmptyAudioGateway();
