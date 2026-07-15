class PlaylistModel {
  const PlaylistModel({
    required this.id,
    required this.name,
    this.description = '',
    this.songIds = const [],
  });

  final String id;
  final String name;
  final String description;
  final List<String> songIds;

  PlaylistModel copyWith({
    String? name,
    String? description,
    List<String>? songIds,
  }) {
    return PlaylistModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      songIds: songIds ?? this.songIds,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'songIds': songIds,
      };

  factory PlaylistModel.fromMap(Map<String, dynamic> map) => PlaylistModel(
        id: '${map['id']}',
        name: '${map['name']}',
        description: '${map['description'] ?? ''}',
        songIds: List<String>.from(map['songIds'] ?? const []),
      );
}

