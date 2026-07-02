import 'package:flutter/material.dart';

import '../../controllers/vibe_controller.dart';
import '../../core/app_colors.dart';
import '../../widgets/common_widgets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.controller,
    required this.onLogout,
  });

  final VibeController controller;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return AppPage(    // Xây dựng màn hình cài đặt của ứng dụng
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 180),
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          SettingTile(     // Hiển thị các tùy chọn cài đặt chung
            icon: Icons.language,
            title: 'Language',
            subtitle: 'Tiếng Việt, Tiếng Anh',
            onTap: () {},
          ),
          const SettingTile(
            icon: Icons.high_quality,
            title: 'Audio Quality',
            subtitle: 'Lossless',
          ),
          const SettingTile(
            icon: Icons.dark_mode,
            title: 'Theme',
            subtitle: 'Midnight Modern',
          ),
          const SettingTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Active',
          ),
          const SettingTile(
            icon: Icons.privacy_tip,
            title: 'Privacy',
            subtitle: 'Manage account privacy',
          ),
          const SettingTile(
            icon: Icons.info,
            title: 'About App',
            subtitle: 'Version 2.4.0 (Build 108)',
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusPill(text: 'PRO'),
                const SizedBox(height: 12),
                const Text(
                  'Pro Member Plan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text('Next billing date: November 12, 2024'),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Manage Plan'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
            label: const Text('Đăng xuất'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
