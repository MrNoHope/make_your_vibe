import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_language.dart';
import '../../widgets/common_widgets.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback onLogout;

  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;

  final AppLanguage language;
  final VoidCallback onLanguageChanged;

  const SettingsPage({
    super.key,
    required this.onLogout,
    required this.darkMode,
    required this.onDarkModeChanged,
    required this.language,
    required this.onLanguageChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool backgroundPlayback = true;
  bool highQuality = true;

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;

    return PageScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TopBar(
            title: lang.text(
              vi: 'Cài đặt',
              en: 'Settings',
            ),
          ),
          const SizedBox(height: 14),
          SettingsTile(
            icon: Icons.language_rounded,
            title: lang.text(
              vi: 'Ngôn ngữ',
              en: 'Language',
            ),
            subtitle: widget.language.label,
            trailing: IconButton(
              onPressed: widget.onLanguageChanged,
              icon: const Icon(Icons.swap_horiz_rounded),
            ),
          ),
          SettingsTile(
            icon: Icons.dark_mode_rounded,
            title: lang.text(
              vi: 'Giao diện tối',
              en: 'Dark Mode',
            ),
            subtitle: widget.darkMode
                ? lang.text(
                    vi: 'Đang dùng giao diện tối',
                    en: 'Dark theme is active',
                  )
                : lang.text(
                    vi: 'Đang dùng giao diện sáng',
                    en: 'Light theme is active',
                  ),
            trailing: Switch(
              value: widget.darkMode,
              onChanged: widget.onDarkModeChanged,
            ),
          ),
          SettingsTile(
            icon: Icons.play_circle_rounded,
            title: lang.text(
              vi: 'Phát nhạc nền',
              en: 'Background Playback',
            ),
            subtitle: lang.text(
              vi: 'Đã kết nối audio service và thông báo điều khiển',
              en: 'Audio service and media notification are active',
            ),
            trailing: Switch(
              value: backgroundPlayback,
              onChanged: (value) {
                setState(() {
                  backgroundPlayback = value;
                });
              },
            ),
          ),
          SettingsTile(
            icon: Icons.high_quality_rounded,
            title: lang.text(
              vi: 'Chất lượng âm thanh',
              en: 'Audio Quality',
            ),
            subtitle: lang.text(
              vi: 'Sẽ được backend điều khiển',
              en: 'Backend controlled',
            ),
            trailing: Switch(
              value: highQuality,
              onChanged: (value) {
                setState(() {
                  highQuality = value;
                });
              },
            ),
          ),
          SettingsTile(
            icon: Icons.cloud_rounded,
            title: 'Backend',
            subtitle: lang.text(
              vi: 'Music API và User API chưa kết nối',
              en: 'Music API and User API pending',
            ),
            trailing: const Icon(Icons.dns_rounded),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout_rounded),
            label: Text(
              lang.text(
                vi: 'Đăng xuất',
                en: 'Logout',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.fromLTRB(13, 12, 8, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.card2 : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.line : const Color(0xFFD4DED4),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.green.withValues(alpha: 0.12),
            child: Icon(
              icon,
              color: AppColors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? AppColors.muted : const Color(0xFF6D786E),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
