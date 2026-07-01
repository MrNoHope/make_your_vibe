import 'package:flutter/material.dart';

import '../../controllers/vibe_controller.dart';
import '../../core/app_colors.dart';
import '../../widgets/common_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.controller,
  });

  final VibeController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.green,
                  child: Text(
                    'MV',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  controller.userName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  controller.email,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                const StatusPill(text: 'SUBSCRIPTION ACTIVE'),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            'ACCOUNT DETAILS',
            style: TextStyle(
              color: AppColors.green,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.badge,
            title: 'Student ID',
            subtitle: controller.studentId,
          ),
          SettingTile(
            icon: Icons.email,
            title: 'Email',
            subtitle: controller.email,
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(
                child: StatBox(
                  value: '1,248 giờ',
                  label: 'Tổng thời gian',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: StatBox(
                  value: 'Lo-fi',
                  label: 'Nghe nhiều',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
