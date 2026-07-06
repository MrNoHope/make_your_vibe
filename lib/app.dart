import 'package:flutter/material.dart';

import 'controllers/vibe_controller.dart';
import 'core/app_language.dart';
import 'core/app_theme.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/main/main_shell.dart';
import 'screens/splash_screen.dart';

class MakeYourVibeApp extends StatefulWidget {
  const MakeYourVibeApp({super.key});

  @override
  State<MakeYourVibeApp> createState() => _MakeYourVibeAppState();
}

class _MakeYourVibeAppState extends State<MakeYourVibeApp> {
  final VibeController controller = VibeController();

  bool loading = true;
  bool loggedIn = false;
  bool darkMode = true;
  AppLanguage language = AppLanguage.vi;

  @override
  void initState() {
    super.initState();
    boot();
  }

  Future<void> boot() async {
    await Future.delayed(const Duration(milliseconds: 650));

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  void enterApp() {
    setState(() {
      loggedIn = true;
    });
  }

  void logout() {
    controller.reset();

    setState(() {
      loggedIn = false;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void setDarkMode(bool value) {
    setState(() {
      darkMode = value;
    });
  }

  void toggleLanguage() {
    setState(() {
      language = language == AppLanguage.vi ? AppLanguage.en : AppLanguage.vi;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Make Your Vibe',
      debugShowCheckedModeBanner: false,
      theme: darkMode ? AppTheme.dark() : AppTheme.light(),
      home: loading
          ? const SplashScreen()
          : loggedIn
          ? MainShell(
        controller: controller,
        onLogout: logout,
        darkMode: darkMode,
        onDarkModeChanged: setDarkMode,
        language: language,
        onLanguageChanged: toggleLanguage,
      )
          : AuthScreen(
        onAuthenticated: enterApp,
      ),
    );
  }
}