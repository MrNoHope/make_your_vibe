import 'package:flutter/material.dart';

import 'controllers/vibe_controller.dart';
import 'core/app_theme.dart';
import 'models/user_profile.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/main/main_shell.dart';
import 'screens/splash_screen.dart';
import 'services/local_backend_service.dart';
import 'services/user_data_service.dart';

void main() {
  runApp(const MakeYourVibeApp());
}

class MakeYourVibeApp extends StatefulWidget {
  const MakeYourVibeApp({super.key});

  @override
  State<MakeYourVibeApp> createState() => _MakeYourVibeAppState();
}

class _MakeYourVibeAppState extends State<MakeYourVibeApp> {
  late final LocalBackendService backend;
  late final LocalUserDataService userDataService;
  late final VibeController controller;

  bool loading = true;
  bool loggedIn = false;

  @override
  void initState() {
    super.initState();
    backend = LocalBackendService();
    userDataService = LocalUserDataService();
    controller = VibeController();
    boot();
  }

  Future<void> boot() async {
    await backend.init();
    await userDataService.init();
    await controller.init();
    await controller.attachUserDataService(userDataService);

    final user = await backend.currentUser();

    if (user != null) {
      controller.setProfile(user.name, user.email, user.studentId);
      await controller.loadUserLibrary();
      loggedIn = true;
    }

    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<bool> login(String email, String password) async {
    final user = await backend.login(email: email, password: password);

    if (user == null) {
      return false;
    }

    controller.setProfile(user.name, user.email, user.studentId);
    await controller.loadUserLibrary();

    setState(() {
      loggedIn = true;
    });

    return true;
  }

  Future<String?> register(UserProfile profile, String password) async {
    final error = await backend.register(
      profile: profile,
      password: password,
    );

    if (error != null) {
      return error;
    }

    controller.setProfile(profile.name, profile.email, profile.studentId);
    await controller.loadUserLibrary();

    setState(() {
      loggedIn = true;
    });

    return null;
  }

  Future<void> logout() async {
    await backend.logout();
    await controller.stopAll();

    if (mounted) {
      setState(() {
        loggedIn = false;
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Make Your Vibe',
          theme: buildAppTheme(),
          home: loading
              ? const SplashScreen()
              : loggedIn
                  ? MainShell(
                      controller: controller,
                      onLogout: logout,
                    )
                  : AuthScreen(
                      onLogin: login,
                      onRegister: register,
                    ),
        );
      },
    );
  }
}
