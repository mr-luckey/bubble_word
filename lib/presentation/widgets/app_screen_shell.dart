import 'package:flutter/material.dart';

import '../../core/widgets/banner_ad_widget.dart';
import '../../core/widgets/nebula_background.dart';
import 'top_status_bar.dart';

/// Shared layout: nebula background, scrollable body, banner ad, optional bottom nav.
class AppScreenShell extends StatelessWidget {
  const AppScreenShell({
    super.key,
    required this.body,
    this.bottomNavIndex,
    this.showBanner = true,
    this.showTopBar = false,
    this.coins,
    this.lives,
    this.lifeRefillSeconds,
  });

  final Widget body;
  final int? bottomNavIndex;
  final bool showBanner;
  final bool showTopBar;
  final int? coins;
  final int? lives;
  final int? lifeRefillSeconds;

  @override
  Widget build(BuildContext context) {
    return NebulaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              if (showTopBar && coins != null && lives != null)
                TopStatusBar(
                  coins: coins!,
                  lives: lives!,
                  lifeRefillSeconds: lifeRefillSeconds ?? 0,
                ),
              Expanded(child: body),
              if (showBanner) const BannerAdWidget(),
              if (bottomNavIndex != null)
                BottomNavBar(currentIndex: bottomNavIndex!),
            ],
          ),
        ),
      ),
    );
  }
}
