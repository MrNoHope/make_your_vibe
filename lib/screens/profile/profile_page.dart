import 'dart:io';

import 'package:flutter/material.dart';

import '../../app_dependencies.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.c});

  final AppController c;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController nameController = TextEditingController(
    text: widget.c.user?.displayName,
  );
  late final TextEditingController bioController = TextEditingController(
    text: widget.c.user?.bio,
  );

  static const accentChoices = [
    0xFF74E26B,
    0xFF7C4DFF,
    0xFFE91E63,
    0xFF00A896,
    0xFF1565C0,
    0xFFFF6D00,
    0xFF6D4C41,
  ];

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final user = c.user!;
    return Scaffold(
      appBar: AppBar(
        title: Text(c.tr('Trang cá nhân', 'Profile')),
        actions: [
          IconButton(
            tooltip: c.tr('Đăng xuất', 'Sign out'),
            onPressed: c.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          SizedBox(
            height: 230,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  bottom: 52,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: _ProfileCover(
                      path: user.coverPath,
                      accent: Color(user.accent),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: IconButton.filledTonal(
                    onPressed: c.pickCover,
                    icon: const Icon(Icons.wallpaper),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Center(
                    child: Stack(
                      children: [
                        Avatar(path: user.avatarPath, radius: 54),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: IconButton.filled(
                            onPressed: c.pickAvatar,
                            icon: const Icon(Icons.camera_alt),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Text(
              user.email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Chip(
              label: Text(
                user.provider == 'email'
                    ? c.tr('Tài khoản local', 'Local account')
                    : '${user.provider.toUpperCase()} DEMO',
              ),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: c.tr('Tên hiển thị', 'Display name'),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: bioController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: c.tr('Giới thiệu', 'Bio'),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => c.updateProfile(
              nameController.text,
              bioController.text,
            ),
            child: Text(c.tr('Lưu hồ sơ', 'Save profile')),
          ),
          const SizedBox(height: 24),
          SectionTitle(c.tr('Màu trang cá nhân', 'Profile accent')),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final value in accentChoices)
                InkWell(
                  onTap: () => c.setAccent(value),
                  borderRadius: BorderRadius.circular(30),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(value),
                    child: user.accent == value
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SectionTitle(c.tr('Cài đặt', 'Settings')),
          SwitchListTile(
            value: c.dark,
            onChanged: c.setTheme,
            title: Text(c.tr('Giao diện tối', 'Dark theme')),
            secondary: const Icon(Icons.dark_mode),
          ),
          SwitchListTile(
            value: c.english,
            onChanged: c.setEnglish,
            title: Text(c.tr('Ngôn ngữ tiếng Anh', 'English language')),
            secondary: const Icon(Icons.language),
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: Text(c.tr('Chế độ dữ liệu', 'Data mode')),
            subtitle: Text(
              c.tr(
                'Local/Demo – không cần backend',
                'Local/Demo – no backend required',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                label: Text(
                  '${c.liked.length} ${c.tr('đã thích', 'liked')}',
                ),
              ),
              Chip(label: Text('${c.playlists.length} playlist')),
              Chip(label: Text('${c.vibes.length} Vibe')),
              Chip(
                label: Text(
                  '${c.uploads.length} ${c.tr('đã đăng', 'uploads')}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileCover extends StatelessWidget {
  const _ProfileCover({required this.path, required this.accent});

  final String path;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final file = path.isEmpty ? null : File(path);
    if (file != null && file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() => Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent,
            Color.lerp(accent, Colors.black, 0.58)!,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.auto_awesome, size: 70, color: Colors.white),
    );
}

