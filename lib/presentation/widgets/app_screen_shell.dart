import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/game_constants.dart';
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
    this.hearts,
    this.maxHearts = GameConstants.maxHearts,
    this.refillSeconds = 0,
    this.heartColor = AppColors.accentRed,
  });

  final Widget body;
  final int? bottomNavIndex;
  final bool showBanner;
  final bool showTopBar;
  final int? hearts;
  final int maxHearts;
  final int refillSeconds;
  final Color heartColor;

  @override
  Widget build(BuildContext context) {
    return NebulaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
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
