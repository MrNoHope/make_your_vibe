import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../models/user_profile.dart';
import '../../services/user_gateway.dart';
import '../../widgets/common_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _avatarPrefix = 'make_your_vibe.profile_avatar.';

  UserProfile? profile;
  Uint8List? customAvatarBytes;
  bool loading = true;
  String message = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadProfile();
    });
  }

  Future<void> loadProfile() async {
    setState(() {
      loading = true;
      message = '';
    });

    try {
      final loadedProfile = await userGateway.getCurrentUser();
      final loadedAvatar = await _loadCustomAvatar(loadedProfile?.id ?? '');

      if (!mounted) return;
      setState(() {
        profile = loadedProfile;
        customAvatarBytes = loadedAvatar;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        loading = false;
        message = '$error';
      });
    }
  }

  Future<void> pickAvatar() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;

    if (bytes == null || bytes.isEmpty) {
      return;
    }

    if (bytes.length > 2 * 1024 * 1024) {
      setState(() {
        message = 'Ảnh quá lớn. Chọn ảnh dưới 2 MB.';
      });
      return;
    }

    final profileId = profile?.id ?? '';
    if (profileId.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_avatarPrefix$profileId', base64Encode(bytes));

    if (!mounted) return;
    setState(() {
      customAvatarBytes = bytes;
      message = 'Đã đổi ảnh hồ sơ.';
    });
  }

  Future<void> resetAvatar() async {
    final profileId = profile?.id ?? '';
    if (profileId.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_avatarPrefix$profileId');

    if (!mounted) return;
    setState(() {
      customAvatarBytes = null;
      message = 'Đã dùng lại avatar tài khoản.';
    });
  }

  Future<Uint8List?> _loadCustomAvatar(String profileId) async {
    if (profileId.isEmpty) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_avatarPrefix$profileId');
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = profile;
    final displayName = _displayName(user);
    final email = user?.email.trim() ?? '';
    final avatarUrl = user?.avatarUrl.trim() ?? '';

    return PageScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TopBar(
            title: 'Hồ sơ',
            action: IconButton(
              tooltip: 'Tải lại',
              onPressed: loading ? null : loadProfile,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: ProfileAvatar(
              customBytes: customAvatarBytes,
              imageUrl: avatarUrl,
              onPick: pickAvatar,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            email.isEmpty ? 'Chưa có email' : email,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: loading ? null : pickAvatar,
                  icon: const Icon(Icons.photo_camera_rounded),
                  label: const Text('Đổi ảnh'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: 'Dùng avatar tài khoản',
                onPressed: customAvatarBytes == null ? null : resetAvatar,
                icon: const Icon(Icons.restart_alt_rounded),
              ),
            ],
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: message.startsWith('Đã')
                    ? AppColors.green
                    : Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 18),
          ProfileInfoTile(
            icon: Icons.account_circle_rounded,
            title: 'Nguồn avatar',
            value: customAvatarBytes == null
                ? avatarUrl.isEmpty
                    ? 'Mặc định'
                    : 'Tài khoản đăng nhập'
                : 'Ảnh đã chọn',
          ),
          ProfileInfoTile(
            icon: Icons.mail_rounded,
            title: 'Email',
            value: email.isEmpty ? 'Chưa có' : email,
          ),
          ProfileInfoTile(
            icon: Icons.verified_user_rounded,
            title: 'UID',
            value: user?.id.isEmpty ?? true ? 'Chưa đăng nhập' : user!.id,
          ),
        ],
      ),
    );
  }

  String _displayName(UserProfile? user) {
    final name = user?.name.trim() ?? '';
    if (name.isNotEmpty) {
      return name;
    }

    final email = user?.email.trim() ?? '';
    if (email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'User profile';
  }
}

class ProfileAvatar extends StatelessWidget {
  final Uint8List? customBytes;
  final String imageUrl;
  final VoidCallback onPick;

  const ProfileAvatar({
    super.key,
    required this.customBytes,
    required this.imageUrl,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = customBytes != null
        ? Image.memory(
            customBytes!,
            width: 92,
            height: 92,
            fit: BoxFit.cover,
          )
        : imageUrl.isEmpty
            ? null
            : Image.network(
                imageUrl,
                width: 92,
                height: 92,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _AvatarFallback(),
              );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.green,
              width: 2,
            ),
            gradient: AppColors.darkGradient,
          ),
          child: ClipOval(
            child: avatar ?? const _AvatarFallback(),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: SizedBox.square(
            dimension: 34,
            child: IconButton.filled(
              tooltip: 'Đổi ảnh',
              onPressed: onPick,
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.edit_rounded,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.person_rounded,
        size: 46,
        color: AppColors.green,
      ),
    );
  }
}

class ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const ProfileInfoTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
