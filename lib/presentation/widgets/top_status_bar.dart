import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/game_constants.dart';

class TopStatusBar extends StatelessWidget {
  const TopStatusBar({
    super.key,
    required this.hearts,
    this.maxHearts = GameConstants.maxHearts,
    this.refillSeconds = 0,
    this.heartColor = AppColors.accentRed,
    this.showBack = false,
  });

  final int hearts;
  final int maxHearts;
  final int refillSeconds;
  final Color heartColor;
  final bool showBack;

  String _formatRefill(int seconds) {
    if (seconds <= 0) return '';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final refill = _formatRefill(refillSeconds);
    final showCountdown = hearts < maxHearts && refillSeconds > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingM,
        AppDimensions.paddingS,
        AppDimensions.paddingM,
        AppDimensions.paddingS,
      ),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => context.go('/home'),
            ),
          const Spacer(),
          Row(
            children: List.generate(maxHearts, (i) {
              final filled = i < hearts;
              return Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  filled ? Icons.favorite : Icons.favorite_border,
                  color: filled ? heartColor : Colors.white38,
                  size: 22,
                ),
              );
            }),
          ),
          if (showCountdown) ...[
            const SizedBox(width: AppDimensions.paddingS),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1040).withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: heartColor.withValues(alpha: 0.7),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, color: heartColor, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    refill,
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      backgroundColor: const Color(0xFF1A1040).withValues(alpha: 0.95),
      indicatorColor: AppColors.neonPurple.withValues(alpha: 0.35),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (i) {
        switch (i) {
          case 0:
            context.go('/home');
          case 1:
            context.go('/daily');
          case 2:
            context.go('/settings');
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: AppStrings.home,
        ),
        NavigationDestination(
          icon: Icon(Icons.local_fire_department_outlined),
          selectedIcon: Icon(Icons.local_fire_department),
          label: AppStrings.daily,
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: AppStrings.settings,
        ),
      ],
    );
  }
}
