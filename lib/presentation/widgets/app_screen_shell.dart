import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/game_constants.dart';
import '../../core/config/ads_config.dart';
import '../../core/utils/quit_dialog.dart';
import '../../core/widgets/banner_ad_widget.dart';
import 'top_status_bar.dart';

/// Tab shell: keeps Home / Daily / Settings alive in an [IndexedStack].
class MainTabShell extends StatelessWidget {
  const MainTabShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_confirmExitApp(context));
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: BottomNavBar(
          currentIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
        ),
      ),
    );
  }
}

Future<void> _confirmExitApp(BuildContext context) async {
  if (!context.mounted) return;
  if (await showQuitAppDialog(context)) {
    await exitApp();
  }
}

/// Shared layout: scrollable body, banner ad, optional top bar.
class AppScreenShell extends StatelessWidget {
  const AppScreenShell({
    super.key,
    required this.body,
    this.showBanner = true,
    this.bannerPlacement = AdsPlacements.home,
    this.showTopBar = false,
    this.hearts,
    this.maxHearts = GameConstants.maxHearts,
    this.refillSeconds = 0,
    this.heartColor = AppColors.accentRed,
  });

  final Widget body;
  final bool showBanner;
  final String bannerPlacement;
  final bool showTopBar;
  final int? hearts;
  final int maxHearts;
  final int refillSeconds;
  final Color heartColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (showTopBar && hearts != null)
              TopStatusBar(
                hearts: hearts!,
                maxHearts: maxHearts,
                refillSeconds: refillSeconds,
                heartColor: heartColor,
              ),
            Expanded(child: body),
            if (showBanner) BannerAdWidget(placement: bannerPlacement),
          ],
        ),
      ),
    );
  }
}
