import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../core/app_language.dart';
import '../../models/user_profile.dart';
import '../../services/user_gateway.dart';
import '../../widgets/common_widgets.dart';

class ProfileScreen extends StatefulWidget {  // Màn hình Hồ sơ: Hiển thị thông tin tài khoản người dùng
  final VoidCallback onLogout;
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final AppLanguage language;
  final VoidCallback onLanguageChanged;

  const ProfileScreen({
    super.key,
    required this.onLogout,
    required this.darkMode,
    required this.onDarkModeChanged,
    required this.language,
    required this.onLanguageChanged,
  });

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

  Future<Uint8List?> pickAvatarBytes() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;

    if (bytes == null || bytes.isEmpty) {
      return null;
    }

    if (bytes.length > 2 * 1024 * 1024) {
      setState(() {
        message = 'Ảnh quá lớn. Chọn ảnh dưới 2 MB.';
      });
      return null;
    }

    return bytes;
  }

  Future<void> showEditProfileDialog() async {
    final profileId = profile?.id ?? '';
    if (profileId.isEmpty) {
      return;
    }

    final nameController = TextEditingController(text: _displayName(profile));
    var draftAvatar = customAvatarBytes;

    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          var busy = false;

          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              backgroundColor: AppColors.card,
              title: Row(
                children: [
                  const Expanded(child: Text('Chỉnh sửa hồ sơ')),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed:
                        busy ? null : () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ProfileAvatarPreview(
                      customBytes: draftAvatar,
                      imageUrl: profile?.avatarUrl.trim() ?? '',
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () async {
                              final picked = await pickAvatarBytes();
                              if (picked == null) {
                                return;
                              }
                              setDialogState(() {
                                draftAvatar = picked;
                              });
                            },
                      icon: const Icon(Icons.upload_rounded),
                      label: const Text('Chọn ảnh từ máy'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên hiển thị',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                FilledButton.icon(
                  onPressed: busy
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            setState(() {
                              message = 'Nhập tên hiển thị.';
                            });
                            return;
                          }

                          setDialogState(() {
                            busy = true;
                          });

                          try {
                            await userGateway.updateDisplayName(name);
                            if (draftAvatar != null) {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setString(
                                '$_avatarPrefix$profileId',
                                base64Encode(draftAvatar!),
                              );
                            }

                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop(true);
                            }
                          } catch (error) {
                            setDialogState(() {
                              busy = false;
                            });
                            if (mounted) {
                              setState(() {
                                message = '$error';
                              });
                            }
                          }
                        },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Lưu'),
                ),
              ],
            ),
          );
        },
      );

      if (saved == true) {
        await loadProfile();
        if (!mounted) {
          return;
        }
        setState(() {
          message = 'Đã cập nhật hồ sơ.';
        });
      }
    } finally {
      nameController.dispose();
    }
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
            action: const SizedBox.shrink(),
          ),
          const SizedBox(height: 18),
          Center(
            child: ProfileAvatar(
              customBytes: customAvatarBytes,
              imageUrl: avatarUrl,
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
          const SizedBox(height: 22),
          _ProfileSettingTile(
            icon: Icons.person_rounded,
            title: widget.language.text(
              vi: 'Hồ sơ',
              en: 'Profile',
            ),
            subtitle: widget.language.text(
              vi: 'Chỉnh tên và ảnh đại diện',
              en: 'Edit name and profile photo',
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.soft,
            ),
            onTap: loading ? null : showEditProfileDialog,
          ),
          _ProfileSettingTile(
            icon: Icons.language_rounded,
            title: widget.language.text(
              vi: 'Ngôn ngữ',
              en: 'Language',
            ),
            subtitle: widget.language.label,
            trailing: IconButton(
              tooltip: widget.language.text(
                vi: 'Đổi ngôn ngữ',
                en: 'Change language',
              ),
              onPressed: widget.onLanguageChanged,
              icon: const Icon(Icons.swap_horiz_rounded),
            ),
          ),
          _ProfileSettingTile(
            icon: widget.darkMode
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            title: widget.language.text(
              vi: 'Giao diện tối',
              en: 'Dark mode',
            ),
            subtitle: widget.darkMode
                ? widget.language.text(
                    vi: 'Đang dùng giao diện tối',
                    en: 'Dark theme is active',
                  )
                : widget.language.text(
                    vi: 'Đang dùng giao diện sáng',
                    en: 'Light theme is active',
                  ),
            trailing: Switch(
              value: widget.darkMode,
              onChanged: widget.onDarkModeChanged,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout_rounded),
              label: Text(
                widget.language.text(
                  vi: 'Đăng xuất',
                  en: 'Logout',
                ),
              ),
            ),
          ),
          const SizedBox(height: 92),
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

class _ProfileSettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _ProfileSettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.card2 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? AppColors.line : AppColors.lightLine,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.green, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? AppColors.muted : AppColors.lightMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  final Uint8List? customBytes;
  final String imageUrl;

  const ProfileAvatar({
    super.key,
    required this.customBytes,
    required this.imageUrl,
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

    return Container(
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
    );
  }
}

class _ProfileAvatarPreview extends StatelessWidget {
  final Uint8List? customBytes;
  final String imageUrl;

  const _ProfileAvatarPreview({
    required this.customBytes,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = customBytes != null
        ? Image.memory(
            customBytes!,
            width: 88,
            height: 88,
            fit: BoxFit.cover,
          )
        : imageUrl.isEmpty
            ? null
            : Image.network(
                imageUrl,
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _AvatarFallback(),
              );

    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.green, width: 2),
        gradient: AppColors.darkGradient,
      ),
      child: ClipOval(
        child: avatar ?? const _AvatarFallback(),
      ),
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
