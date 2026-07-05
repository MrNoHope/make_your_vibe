import '../models/user_profile.dart';

abstract class UserGateway {
  Future<UserProfile?> getCurrentUser();
  Future<bool> login(String email, String password);
  Future<bool> register(String name, String email, String password);
  Future<void> logout();
}

class EmptyUserGateway implements UserGateway {
  const EmptyUserGateway();

  @override
  Future<UserProfile?> getCurrentUser() async {
    return null;
  }

  @override
  Future<bool> login(String email, String password) async {
    return true;
  }

  @override
  Future<bool> register(String name, String email, String password) async {
    return true;
  }

  @override
  Future<void> logout() async {}
}

const UserGateway userGateway = EmptyUserGateway();