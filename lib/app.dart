import 'package:flutter/material.dart';

import 'controllers/app_controller.dart';
import 'core/app_theme.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/main/main_shell.dart';
import 'screens/splash/splash_screen.dart';

class MakeYourVibeApp extends StatelessWidget {
  const MakeYourVibeApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Make Your Vibe',
        themeMode: controller.dark ? ThemeMode.dark : ThemeMode.light,
        theme: buildAppTheme(brightness: Brightness.light),
        darkTheme: buildAppTheme(brightness: Brightness.dark),
        home: !controller.initialized
            ? const SplashScreen()
            : controller.user == null
                ? AuthScreen(c: controller)
                : MainShell(c: controller),
      ),
    );
  }
}
