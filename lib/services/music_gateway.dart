import 'dart:async';

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
  YoutubeMusicGateway({YoutubeExplode? youtube})
      : _yt = youtube ?? YoutubeExplode();

  static const _networkTimeout = Duration(seconds: 14);


  final YoutubeExplode _yt;
//
  @override
  Future<List<Song>> getHomeTracks() {
    return searchTracks('vpop chill');
  }

  @override
  Future<List<Song>> searchTracks(String keyword) async {
    final query = keyword.trim();

    if (query.isEmpty) {
      return [];
    }

    final videos = await _yt.search.search(query).timeout(
          _networkTimeout,
          onTimeout: () => throw TimeoutException(
            'Ket noi YouTube qua lau. Kiem tra mang roi thu lai.',
          ),
        );

    return videos.take(20).map(_songFromVideo).toList(growable: false);
  }

  @override
  Future<Song> resolveStream(Song song) async {
    final videoId = _youtubeVideoId(song);

    if (videoId.isEmpty) {
      if (song.hasStream) {
        return song;
      }
      throw Exception('Bai hat chua co YouTube video id hoac streamUrl');
    }

    final manifest = await _yt.videos.streams.getManifest(
      videoId,
      ytClients: [
        YoutubeApiClient.ios,
        YoutubeApiClient.androidVr,
      ],
    ).timeout(
      _networkTimeout,
      onTimeout: () => throw TimeoutException(
        'Lay stream YouTube qua lau. Kiem tra mang roi thu lai.',
      ),
    );
    final streamInfo = _bestAudioStream(manifest);

    if (streamInfo == null) {
      throw Exception('Khong lay duoc stream YouTube cho bai nay');
    }

    return song.copyWith(
      id: videoId,
      streamUrl: streamInfo.url.toString(),
      sourceType: 'youtube',
      sourceId: videoId,
    );
  }

  @override
  Future<List<Playlist>> getPlaylists() async {
    return [];
  }

  @override
  void close() {
    _yt.close();
  }

  Song _songFromVideo(Video video) {
    final videoId = video.id.value;

    return Song(
      id: videoId,
      title: video.title,
      artist: video.author,
      album: 'YouTube',
      coverUrl: video.thumbnails.highResUrl,
      duration: video.duration ?? Duration.zero,
      streamUrl: '',
      sourceType: 'youtube',
      sourceId: videoId,
    );
  }

  AudioStreamInfo? _bestAudioStream(StreamManifest manifest) {
    final audioOnly = manifest.audioOnly.toList();
    audioOnly.sort(
      (left, right) => right.bitrate.bitsPerSecond.compareTo(
        left.bitrate.bitsPerSecond,
      ),
    );

    if (audioOnly.isNotEmpty) {
      return audioOnly.first;
    }

    final muxed = manifest.muxed.toList();
    muxed.sort(
      (left, right) => right.bitrate.bitsPerSecond.compareTo(
        left.bitrate.bitsPerSecond,
      ),
    );

    return muxed.isEmpty ? null : muxed.first;
  }

  String _youtubeVideoId(Song song) {
    if (song.sourceType == 'youtube' && song.sourceId.trim().isNotEmpty) {
      return song.sourceId.trim();
    }

    final id = song.id.trim();
    return RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id) ? id : '';
  }
}

final MusicGateway musicGateway = YoutubeMusicGateway();
