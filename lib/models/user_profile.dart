class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.bio = '',
    this.avatarPath = '',
    this.coverPath = '',
    this.accent = 0xFF74E26B,
    this.provider = 'email',
  });

  final String id;
  final String email;
  final String displayName;
  final String bio;
  final String avatarPath;
  final String coverPath;
  final int accent;
  final String provider;

  UserProfile copyWith({
    String? displayName,
    String? bio,
    String? avatarPath,
    String? coverPath,
    int? accent,
  }) {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarPath: avatarPath ?? this.avatarPath,
      coverPath: coverPath ?? this.coverPath,
      accent: accent ?? this.accent,
      provider: provider,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'bio': bio,
        'avatarPath': avatarPath,
        'coverPath': coverPath,
        'accent': accent,
        'provider': provider,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: '${map['id']}',
        email: '${map['email']}',
        displayName: '${map['displayName']}',
        bio: '${map['bio'] ?? ''}',
        avatarPath: '${map['avatarPath'] ?? ''}',
        coverPath: '${map['coverPath'] ?? ''}',
        accent: (map['accent'] as num?)?.toInt() ?? 0xFF74E26B,
        provider: '${map['provider'] ?? 'email'}',
      );
}

