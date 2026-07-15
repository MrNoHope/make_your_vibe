class VibePreset {
  const VibePreset({
    required this.id,
    required this.name,
    this.description = '',
    this.coverPath = '',
    this.songId = '',
    this.levels = const {},
    this.masterVolume = 0.8,
    this.isPublic = false,
    this.likes = 0,
  });

  final String id;
  final String name;
  final String description;
  final String coverPath;
  final String songId;
  final Map<String, double> levels;
  final double masterVolume;
  final bool isPublic;
  final int likes;

  VibePreset copyWith({
    String? name,
    String? description,
    String? coverPath,
    String? songId,
    Map<String, double>? levels,
    double? masterVolume,
    bool? isPublic,
    int? likes,
  }) {
    return VibePreset(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverPath: coverPath ?? this.coverPath,
      songId: songId ?? this.songId,
      levels: levels ?? this.levels,
      masterVolume: masterVolume ?? this.masterVolume,
      isPublic: isPublic ?? this.isPublic,
      likes: likes ?? this.likes,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'coverPath': coverPath,
        'songId': songId,
        'levels': levels,
        'masterVolume': masterVolume,
        'isPublic': isPublic,
        'likes': likes,
      };

  factory VibePreset.fromMap(Map<String, dynamic> map) => VibePreset(
        id: '${map['id']}',
        name: '${map['name']}',
        description: '${map['description'] ?? ''}',
        coverPath: '${map['coverPath'] ?? ''}',
        songId: '${map['songId'] ?? ''}',
        levels: Map<String, double>.from(
          (map['levels'] ?? {}).map(
            (key, value) => MapEntry('$key', (value as num).toDouble()),
          ),
        ),
        masterVolume: (map['masterVolume'] as num?)?.toDouble() ?? 0.8,
        isPublic: map['isPublic'] == true,
        likes: (map['likes'] as num?)?.toInt() ?? 0,
      );
}

