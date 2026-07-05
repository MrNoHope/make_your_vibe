import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../widgets/common_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageScroll(
      child: Column(
        children: [
          const TopBar(title: 'Make Your Vibe'),
          const SizedBox(height: 18),
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.green,
                width: 2,
              ),
              gradient: AppColors.darkGradient,
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 46,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'User profile',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Loaded from user backend later',
            style: TextStyle(
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 20),
          const BackendNotice(
            icon: Icons.account_circle_rounded,
            title: 'No local user data',
            message:
            'Name, email, avatar, premium plan, playlists and statistics will come from backend.',
          ),
          const SizedBox(height: 14),
          const ProfileInfoTile(
            icon: Icons.mail_rounded,
            title: 'Email',
            value: 'Backend pending',
          ),
          const ProfileInfoTile(
            icon: Icons.favorite_rounded,
            title: 'Liked songs',
            value: 'Backend pending',
          ),
          const ProfileInfoTile(
            icon: Icons.queue_music_rounded,
            title: 'Playlists',
            value: 'Backend pending',
          ),
        ],
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
          Text(
            value,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}