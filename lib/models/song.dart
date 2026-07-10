class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String coverUrl;
  final Duration duration;
  final String streamUrl;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album = '',
    this.coverUrl = '',
    this.duration = Duration.zero,
    this.streamUrl = '',
  });

  bool get hasStream => streamUrl.trim().isNotEmpty;

  String get durationText {
    final seconds = duration.inSeconds;

    if (seconds <= 0) {
      return '--:--';
    }

    final minutes = seconds ~/ 60;
    final remain = seconds % 60;

    return '$minutes:${remain.toString().padLeft(2, '0')}';
  }

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? coverUrl,
    Duration? duration,
    String? streamUrl,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      coverUrl: coverUrl ?? this.coverUrl,
      duration: duration ?? this.duration,
      streamUrl: streamUrl ?? this.streamUrl,
    );
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      artist: '${json['artist'] ?? ''}',
      album: '${json['album'] ?? ''}',
      coverUrl: '${json['coverUrl'] ?? json['thumbnail'] ?? ''}',
      duration: Duration(
        seconds: _toInt(json['durationSeconds'] ?? json['duration']),
      ),
      streamUrl: '${json['streamUrl'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'coverUrl': coverUrl,
      'durationSeconds': duration.inSeconds,
      'streamUrl': streamUrl,
    };
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
