import '../models/playlist.dart';
import '../models/song.dart';

abstract class MusicGateway {
  Future<List<Song>> getHomeTracks();
  Future<List<Song>> searchTracks(String keyword);
  Future<List<Playlist>> getPlaylists();
}

class EmptyMusicGateway implements MusicGateway {
  const EmptyMusicGateway();

  @override
  Future<List<Song>> getHomeTracks() async {
    return [];
  }

  @override
  Future<List<Song>> searchTracks(String keyword) async {
    return [];
  }

  @override
  Future<List<Playlist>> getPlaylists() async {
    return [];
  }
}

const MusicGateway musicGateway = EmptyMusicGateway();