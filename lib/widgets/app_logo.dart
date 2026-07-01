import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    required this.size,
    this.showText = false,
  });

  final double size;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF54D66A), Color(0xFF0B2711)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withOpacity(0.32),
            blurRadius: 34,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.50,
          height: size * 0.50,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.background,
          ),
          child: Icon(
            Icons.graphic_eq,
            color: AppColors.green,
            size: size * 0.30,
          ),
        ),
      ),
    );

    if (!showText) {
      return mark;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(height: 22),
        const Text(
          'Make Your Vibe',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Music meets atmosphere',
          style: TextStyle(color: AppColors.muted),
        ),
      ],
    );
  }
}
