class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String coverUrl;
  final Duration duration;
  final String streamUrl;
  final String databaseId;
  final String sourceType;
  final String sourceId;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album = '',
    this.coverUrl = '',
    this.duration = Duration.zero,
    this.streamUrl = '',
    this.databaseId = '',
    this.sourceType = '',
    this.sourceId = '',
  });

  bool get hasStream => streamUrl.trim().isNotEmpty;

  bool get isYoutube =>
      sourceType == 'youtube' || (!hasStream && _isVideoId(id));

  String get storedId {
    final cleanDatabaseId = databaseId.trim();
    return cleanDatabaseId.isEmpty ? id.trim() : cleanDatabaseId;
  }

  String get youtubeVideoId {
    final cleanSourceId = sourceId.trim();
    if (sourceType == 'youtube' && cleanSourceId.isNotEmpty) {
      return cleanSourceId;
    }
    return id.trim();
  }

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
    String? databaseId,
    String? sourceType,
    String? sourceId,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      coverUrl: coverUrl ?? this.coverUrl,
      duration: duration ?? this.duration,
      streamUrl: streamUrl ?? this.streamUrl,
      databaseId: databaseId ?? this.databaseId,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
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
      databaseId: '${json['databaseId'] ?? json['dbId'] ?? ''}',
      sourceType: '${json['sourceType'] ?? ''}',
      sourceId: '${json['sourceId'] ?? ''}',
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
      'databaseId': databaseId,
      'sourceType': sourceType,
      'sourceId': sourceId,
    };
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static bool _isVideoId(String value) {
    return RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(value.trim());
  }
}
