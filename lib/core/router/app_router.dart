import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/daily_challenge_screen.dart';
import '../../presentation/screens/game_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/settings_screen.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/widgets/app_screen_shell.dart';

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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainTabShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/daily',
                builder: (_, __) => const DailyChallengeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, __) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/game/:levelId',
        builder: (_, state) {
          final id = int.parse(state.pathParameters['levelId']!);
          final isDaily = state.uri.queryParameters['daily'] == 'true';
          return GameScreen(
            key: ValueKey('game-$id-daily-$isDaily'),
            levelId: id,
            isDailyChallenge: isDaily,
          );
        },
      ),
    ],
  );
}
