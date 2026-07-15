import 'package:flutter/material.dart';

import '../../app_dependencies.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(size: 112),
            SizedBox(height: 32),
            Text(
              'Make Your Vibe',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            SizedBox(height: 22),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
