class UserProfile {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;

  const UserProfile({
    this.id = '',
    this.name = '',
    this.email = '',
    this.avatarUrl = '',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      email: '${json['email'] ?? ''}',
      avatarUrl: '${json['avatarUrl'] ?? ''}',
    );
  }
}