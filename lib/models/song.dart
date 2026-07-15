enum SongSource { youtube, local }

class Song {
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    this.artworkUrl = '',
    this.durationMs = 0,
    this.source = SongSource.youtube,
    this.localPath = '',
    this.streamUrl = '',
    this.isPublic = false,
  });

  final String id;
  final String title;
  final String artist;
  final String artworkUrl;
  final int durationMs;
  final SongSource source;
  final String localPath;
  final String streamUrl;
  final bool isPublic;

  Duration get duration => Duration(milliseconds: durationMs);

  Song copyWith({
    String? title,
    String? artist,
    String? artworkUrl,
    int? durationMs,
    SongSource? source,
    String? localPath,
    String? streamUrl,
    bool? isPublic,
  }) {
    return Song(
      id: id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      durationMs: durationMs ?? this.durationMs,
      source: source ?? this.source,
      localPath: localPath ?? this.localPath,
      streamUrl: streamUrl ?? this.streamUrl,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'artist': artist,
        'artworkUrl': artworkUrl,
        'durationMs': durationMs,
        'source': source.name,
        'localPath': localPath,
        'streamUrl': source == SongSource.local ? streamUrl : '',
        'isPublic': isPublic,
      };

  factory Song.fromMap(Map<String, dynamic> map) {
    final source = '${map['source']}' == 'local'
        ? SongSource.local
        : SongSource.youtube;
    return Song(
      id: '${map['id']}',
      title: '${map['title']}',
      artist: '${map['artist']}',
      artworkUrl: '${map['artworkUrl'] ?? ''}',
      durationMs: (map['durationMs'] as num?)?.toInt() ?? 0,
      source: source,
      localPath: '${map['localPath'] ?? ''}',
      streamUrl: source == SongSource.local ? '${map['streamUrl'] ?? ''}' : '',
      isPublic: map['isPublic'] == true,
    );
  }
}

