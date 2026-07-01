import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../widgets/app_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: AppLogo(
          size: 116,
          showText: true,
        ),
      ),
    );
  }
}
