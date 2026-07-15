import 'dart:convert';

import '../models/models.dart';
import 'local_store.dart';

class LocalAuthService {
  LocalAuthService(this.store);

  final LocalStore store;

  List<Map<String, dynamic>> get _users => store.getMaps('auth_users');

  Future<UserProfile> register(
    String name,
    String email,
    String password,
  ) async {
    final mail = email.trim().toLowerCase();
    if (name.trim().length < 2) {
      throw Exception('Tên phải có ít nhất 2 ký tự.');
    }
    if (!mail.contains('@') || password.length < 6) {
      throw Exception('Email hoặc mật khẩu chưa hợp lệ.');
    }

    final users = _users;
    if (users.any((item) => item['email'] == mail)) {
      throw Exception('Email này đã được đăng ký.');
    }

    final profile = UserProfile(
      id: 'u_${DateTime.now().microsecondsSinceEpoch}',
      email: mail,
      displayName: name.trim(),
    );
    users.add({
      'email': mail,
      'password': password,
      'profile': profile.toMap(),
    });
    await store.setMaps('auth_users', users);
    await _setCurrent(profile);
    return profile;
  }

  Future<UserProfile> login(String email, String password) async {
    final mail = email.trim().toLowerCase();
    final matches = _users
        .where((item) => item['email'] == mail && item['password'] == password)
        .toList();
    if (matches.isEmpty) {
      throw Exception('Sai email hoặc mật khẩu.');
    }
    final profile = UserProfile.fromMap(
      Map<String, dynamic>.from(matches.first['profile'] as Map),
    );
    await _setCurrent(profile);
    return profile;
  }

  Future<UserProfile> social(String provider) async {
    final email = 'demo@$provider.local';
    final users = _users;
    final index = users.indexWhere((item) => item['email'] == email);
    UserProfile profile;

    if (index >= 0) {
      profile = UserProfile.fromMap(
        Map<String, dynamic>.from(users[index]['profile'] as Map),
      );
    } else {
      profile = UserProfile(
        id: '${provider}_demo',
        email: email,
        displayName:
            provider == 'google' ? 'Google Demo User' : 'Facebook Demo User',
        provider: provider,
      );
      users.add({
        'email': email,
        'password': '',
        'profile': profile.toMap(),
      });
      await store.setMaps('auth_users', users);
    }

    await _setCurrent(profile);
    return profile;
  }

  UserProfile? restore() {
    final raw = store.getString('current_user');
    if (raw == null || raw.isEmpty) return null;
    try {
      return UserProfile.fromMap(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> update(UserProfile profile) async {
    await _setCurrent(profile);
    final users = _users;
    final index = users.indexWhere((item) => item['email'] == profile.email);
    if (index >= 0) {
      users[index]['profile'] = profile.toMap();
    } else {
      users.add({
        'email': profile.email,
        'password': '',
        'profile': profile.toMap(),
      });
    }
    await store.setMaps('auth_users', users);
  }

  Future<void> logout() => store.setString('current_user', '');

  Future<void> _setCurrent(UserProfile profile) =>
      store.setString('current_user', jsonEncode(profile.toMap()));
}

