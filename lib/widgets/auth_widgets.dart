import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class AuthHint extends StatelessWidget {
  final String text;

  const AuthHint({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.soft,
        height: 1.35,
      ),
    );
  }
}