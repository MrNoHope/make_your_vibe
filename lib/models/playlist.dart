import 'song.dart';

class Playlist {
  final String id;
  final String title;
  final String subtitle;
  final String coverUrl;
  final List<Song> songs;
  final String shareId;
  final bool isShared;
  final bool shareActive;
  final bool canShare;
  final int viewCount;
  final int importCount;
  final int favoriteCount;
  final int inviteCount;

  const Playlist({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.coverUrl = '',
    this.songs = const [],
    this.shareId = '',
    this.isShared = false,
    this.shareActive = true,
    this.canShare = false,
    this.viewCount = 0,
    this.importCount = 0,
    this.favoriteCount = 0,
    this.inviteCount = 0,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final rawSongs = json['songs'];

    return Playlist(
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      subtitle: '${json['subtitle'] ?? ''}',
      coverUrl: '${json['coverUrl'] ?? ''}',
      shareId: '${json['shareId'] ?? ''}',
      isShared: json['isShared'] == true,
      shareActive: json['shareActive'] != false,
      canShare: json['canShare'] == true,
      viewCount: _toInt(json['viewCount']),
      importCount: _toInt(json['importCount']),
      favoriteCount: _toInt(json['favoriteCount']),
      inviteCount: _toInt(json['inviteCount']),
      songs: rawSongs is List
          ? rawSongs
              .whereType<Map<String, dynamic>>()
              .map(Song.fromJson)
              .toList()
          : const [],
    );
  }

  Playlist copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? coverUrl,
    List<Song>? songs,
    String? shareId,
    bool? isShared,
    bool? shareActive,
    bool? canShare,
    int? viewCount,
    int? importCount,
    int? favoriteCount,
    int? inviteCount,
  }) {
    return Playlist(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      coverUrl: coverUrl ?? this.coverUrl,
      songs: songs ?? this.songs,
      shareId: shareId ?? this.shareId,
      isShared: isShared ?? this.isShared,
      shareActive: shareActive ?? this.shareActive,
      canShare: canShare ?? this.canShare,
      viewCount: viewCount ?? this.viewCount,
      importCount: importCount ?? this.importCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      inviteCount: inviteCount ?? this.inviteCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'coverUrl': coverUrl,
      'songs': songs.map((song) => song.toJson()).toList(growable: false),
      'shareId': shareId,
      'isShared': isShared,
      'shareActive': shareActive,
      'canShare': canShare,
      'viewCount': viewCount,
      'importCount': importCount,
      'favoriteCount': favoriteCount,
      'inviteCount': inviteCount,
    };
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
