class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.studentId,
  });

  final String name;
  final String email;
  final String studentId;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'studentId': studentId,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      studentId: (json['studentId'] ?? '').toString(),
    );
  }
}
