import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Playlist;

import '../models/playlist.dart';
import '../models/song.dart';

abstract class MusicGateway {
  Future<List<Song>> getHomeTracks();
  Future<List<Song>> searchTracks(String keyword);
  Future<Song> resolveStream(Song song);
  Future<List<Playlist>> getPlaylists();
  void close();
}

class YoutubeMusicGateway implements MusicGateway {
  final YoutubeExplode _yt = YoutubeExplode();

  @override
  Future<List<Song>> getHomeTracks() {
    return searchTracks('vietnam music');
  }

  @override
  Future<List<Song>> searchTracks(String keyword) async {
    final query = keyword.trim();

    if (query.isEmpty) {
      return [];
    }

    final videos = await _yt.search.search(query);

    return videos.take(20).map((video) {
      return Song(
        id: video.id.value,
        title: video.title,
        artist: video.author,
        coverUrl: video.thumbnails.highResUrl,
        duration: video.duration ?? Duration.zero,
      );
    }).toList();
  }

  @override
  Future<Song> resolveStream(Song song) async {
    if (song.hasStream) {
      return song;
    }

    final manifest = await _yt.videos.streams.getManifest(
      song.id,
      ytClients: [
        YoutubeApiClient.ios,
        YoutubeApiClient.androidVr,
      ],
    );

    if (manifest.audioOnly.isNotEmpty) {
      final streamUrl = manifest.audioOnly.first.url.toString();
      return song.copyWith(streamUrl: streamUrl);
    }

    if (manifest.muxed.isNotEmpty) {
      final streamUrl = manifest.muxed.first.url.toString();
      return song.copyWith(streamUrl: streamUrl);
    }

    throw Exception('Không lấy được stream cho bài này');
  }

  @override
  Future<List<Playlist>> getPlaylists() async {
    return [];
  }

  @override
  void close() {
    _yt.close();
  }
}

final MusicGateway musicGateway = YoutubeMusicGateway();