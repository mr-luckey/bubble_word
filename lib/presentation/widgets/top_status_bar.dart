import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';

class TopStatusBar extends StatelessWidget {
  const TopStatusBar({
    super.key,
    required this.coins,
    required this.lives,
    this.lifeRefillSeconds = 0,
    this.showBack = false,
  });

  final int coins;
  final int lives;
  final int lifeRefillSeconds;
  final bool showBack;

  String _formatRefill(int seconds) {
    if (seconds <= 0) return '';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final refill = _formatRefill(lifeRefillSeconds);
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
          _Badge(
            icon: Icons.monetization_on,
            value: '$coins',
            color: AppColors.neonGold,
            borderColor: AppColors.neonGold,
          ),
          const SizedBox(width: AppDimensions.paddingS),
          _Badge(
            icon: Icons.favorite,
            value: lives > 0 ? '$lives' : refill,
            color: AppColors.accentRed,
            borderColor: AppColors.accentRed,
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.value,
    required this.color,
    required this.borderColor,
  });

  final IconData icon;
  final String value;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1040).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.25),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
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
