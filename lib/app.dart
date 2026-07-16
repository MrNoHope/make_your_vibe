import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controllers/vibe_controller.dart';
import 'core/app_language.dart';
import 'core/app_theme.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/main/main_shell.dart';
import 'screens/splash_screen.dart';
import 'services/user_gateway.dart';

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
    _syncSystemChrome();
    boot();
  }

  Future<void> boot() async {
    await Future.delayed(const Duration(milliseconds: 650));

    if (!mounted) return;

    final user = await _loadCurrentUser();

    setState(() {
      loading = false;
      loggedIn = user != null;
    });
  }

  Future<Object?> _loadCurrentUser() async {
    try {
      return await userGateway.getCurrentUser();
    } catch (_) {
      return null;
    }
  }

  void enterApp() {
    setState(() {
      loggedIn = true;
    });
  }

  Future<void> logout() async {
    await controller.reset();
    await userGateway.logout();

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
    _syncSystemChrome(value);
    setState(() {
      darkMode = value;
    });
  }

  void _syncSystemChrome([bool? value]) {
    SystemChrome.setSystemUIOverlayStyle(
      AppTheme.systemOverlayStyle(value ?? darkMode),
    );
  }

  void toggleLanguage() {
    setState(() {
      language = language == AppLanguage.vi ? AppLanguage.en : AppLanguage.vi;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = darkMode ? AppTheme.dark() : AppTheme.light();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlayStyle(darkMode),
      child: MaterialApp(
        title: 'Make Your Vibe',
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: loading
            ? const SplashScreen()
            : loggedIn
                ? MainShell(
                    controller: controller,
                    onLogout: () {
                      logout();
                    },
                    darkMode: darkMode,
                    onDarkModeChanged: setDarkMode,
                    language: language,
                    onLanguageChanged: toggleLanguage,
                  )
                : AuthScreen(
                    onAuthenticated: enterApp,
                  ),
      ),
    );
  }
}
