import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({
    super.key,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.greenGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Icon(
        Icons.graphic_eq_rounded,
        color: Colors.black,
        size: size * 0.48,
      ),
    );
  }
}