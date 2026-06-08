import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/controllers/app_locale_controller.dart';
import 'core/controllers/app_navigation_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/home/screens/home_screen.dart';
import 'features/player/controllers/vibe_player_controller.dart';

void main() {
  runApp(const MakeYourVibeApp());
}

class MakeYourVibeApp extends StatelessWidget {
  const MakeYourVibeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => VibePlayerController(),
        ),
        ChangeNotifierProvider(
          create: (_) => AppLocaleController(),
        ),
        ChangeNotifierProvider(
          create: (_) => AppNavigationController(),
        ),
      ],
      child: MaterialApp(
        title: 'Make Your Vibe',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}