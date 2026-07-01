import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

class LocalBackendService {
  static const usersKey = 'make_your_vibe_users';
  static const sessionKey = 'make_your_vibe_current_email';

  late final SharedPreferences prefs;

  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    await seedAccount();
  }

  Future<void> seedAccount() async {
    final users = readUsers();

    final exists = users.any((item) {
      return (item['email'] ?? '').toString().toLowerCase() == 'umter@st.vibe.app';
    });

    if (exists) {
      return;
    }

    users.add({
      'name': 'Nguyễn Lương Nghĩa',
      'email': 'umter@st.vibe.app',
      'studentId': '2302700033',
      'password': '123456',
    });

    await saveUsers(users);
  }

  List<Map<String, dynamic>> readUsers() {
    final raw = prefs.getString(usersKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      return [];
    }

    return decoded.map((item) {
      return Map<String, dynamic>.from(item as Map);
    }).toList();
  }

  Future<void> saveUsers(List<Map<String, dynamic>> users) {
    return prefs.setString(usersKey, jsonEncode(users));
  }

  Future<UserProfile?> currentUser() async {
    final email = prefs.getString(sessionKey);

    if (email == null) {
      return null;
    }

    final users = readUsers();

    final matches = users.where((item) {
      return (item['email'] ?? '').toString().toLowerCase() == email.toLowerCase();
    }).toList();

    if (matches.isEmpty) {
      return null;
    }

    return UserProfile.fromJson(matches.first);
  }

  Future<UserProfile?> login({
    required String email,
    required String password,
  }) async {
    final users = readUsers();
    final normalized = email.trim().toLowerCase();

    for (final user in users) {
      final userEmail = (user['email'] ?? '').toString().toLowerCase();
      final userPassword = (user['password'] ?? '').toString();

      if (userEmail == normalized && userPassword == password) {
        await prefs.setString(sessionKey, user['email'].toString());
        return UserProfile.fromJson(user);
      }
    }

    return null;
  }

  Future<String?> register({
    required UserProfile profile,
    required String password,
  }) async {
    final name = profile.name.trim();
    final email = profile.email.trim().toLowerCase();
    final studentId = profile.studentId.trim();

    if (name.isEmpty || email.isEmpty || studentId.isEmpty || password.length < 6) {
      return 'Vui lòng nhập đủ thông tin. Mật khẩu tối thiểu 6 ký tự.';
    }

    final users = readUsers();

    final exists = users.any((item) {
      return (item['email'] ?? '').toString().toLowerCase() == email;
    });

    if (exists) {
      return 'Email này đã tồn tại.';
    }

    users.add({
      'name': name,
      'email': email,
      'studentId': studentId,
      'password': password,
    });

    await saveUsers(users);
    await prefs.setString(sessionKey, email);

    return null;
  }

  Future<void> logout() async {
    await prefs.remove(sessionKey);
  }
}
