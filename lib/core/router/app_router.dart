import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/daily_challenge_screen.dart';
import '../../presentation/screens/game_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/settings_screen.dart';
import '../../presentation/screens/shop_screen.dart';
import '../../presentation/screens/splash_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/game/:levelId',
        builder: (_, state) {
          final id = int.parse(state.pathParameters['levelId']!);
          return GameScreen(key: ValueKey('game-$id'), levelId: id);
        },
      ),
      GoRoute(
        path: '/shop',
        builder: (_, __) => const ShopScreen(),
      ),
      GoRoute(
        path: '/daily',
        builder: (_, __) => const DailyChallengeScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
      ),
    ],
  );
}
