import 'song.dart';

class Playlist {
  final String id;
  final String title;
  final String subtitle;
  final String coverUrl;
  final List<Song> songs;

  const Playlist({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.coverUrl = '',
    this.songs = const [],
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final rawSongs = json['songs'];

    return Playlist(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      subtitle: '${json['subtitle'] ?? ''}',
      coverUrl: '${json['coverUrl'] ?? ''}',
      songs: rawSongs is List
          ? rawSongs
          .whereType<Map<String, dynamic>>()
          .map(Song.fromJson)
          .toList()
          : const [],
    );
  }
}