part of app_controller;

extension AppProfileActions on AppController {
  Future<void> updateProfile(String name, String bio) async {
    if (user == null) return;
    user = user!.copyWith(
      displayName: name.trim().isEmpty ? user!.displayName : name.trim(),
      bio: bio.trim(),
    );
    await auth.update(user!);
    notifyListeners();
  }

  Future<void> pickAvatar() async {
    if (user == null) return;
    final path = await media.pickAndCopy(
      type: FileType.image,
      folder: '${user!.id}/profile',
    );
    if (path.isEmpty) return;
    user = user!.copyWith(avatarPath: path);
    await auth.update(user!);
    notifyListeners();
  }

  Future<void> pickCover() async {
    if (user == null) return;
    final path = await media.pickAndCopy(
      type: FileType.image,
      folder: '${user!.id}/profile',
    );
    if (path.isEmpty) return;
    user = user!.copyWith(coverPath: path);
    await auth.update(user!);
    notifyListeners();
  }

  Future<void> setAccent(int value) async {
    if (user == null) return;
    user = user!.copyWith(accent: value);
    await auth.update(user!);
    notifyListeners();
  }

  Future<void> setTheme(bool value) async {
    dark = value;
    await store.setBool('dark', value);
    notifyListeners();
  }

  Future<void> setEnglish(bool value) async {
    english = value;
    await store.setBool('english', value);
    notifyListeners();
  }
}
